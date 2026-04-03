from __future__ import annotations

from fastapi import HTTPException, status

from app.core.cache import cache
from app.core.config import settings
from app.core.rate_limiter import rate_limiter
from app.db.supabase_client import supabase
from app.schemas.notification import NotificationCreateInternal
from app.schemas.team import CreateTeamRequest
from app.services.gamification_service import GamificationService
from app.services.notification_service import NotificationService


class TeamService:
    def __init__(self) -> None:
        self._notifications = NotificationService()
        self._gamification = GamificationService()

    def create_team(self, user_id: str, payload: CreateTeamRequest) -> dict:
        hackathon_id = str(payload.hackathon_id)
        self._ensure_hackathon_exists(hackathon_id)
        self._ensure_user_not_in_accepted_team(user_id, hackathon_id)

        team_insert_payload = {
            "hackathon_id": hackathon_id,
            "creator_id": user_id,
            "name": payload.name,
            "description": payload.description,
            "required_skills": payload.required_skills,
            "max_members": payload.max_members,
        }

        created_team_response = (
            supabase.table("teams").insert(team_insert_payload).execute()
        )
        created_rows = created_team_response.data or []
        if not created_rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create team.",
            )

        created_team = created_rows[0]

        try:
            supabase.table("team_members").insert(
                {
                    "team_id": created_team["id"],
                    "user_id": user_id,
                    "role": "leader",
                    "status": "accepted",
                }
            ).execute()
        except Exception as exc:
            # Compensating action: avoid orphan teams if leader membership insert fails.
            supabase.table("teams").delete().eq("id", created_team["id"]).execute()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to finalize team creation.",
            ) from exc
        self._invalidate_recommendations_cache_for_hackathon(hackathon_id)

        return {
            "team_id": created_team["id"],
            "message": "Team created successfully.",
        }

    def _ensure_hackathon_exists(self, hackathon_id: str) -> None:
        rows = (
            supabase.table("hackathons")
            .select("id")
            .eq("id", hackathon_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid hackathon_id.",
            )

    def join_team(self, user_id: str, team_id: str) -> dict:
        team_id = str(team_id)
        rate_limiter.check(
            user_id=user_id,
            action="team_join",
            limit=settings.team_join_limit_per_10min,
            window_seconds=600,
        )

        team = self._get_team(team_id)
        hackathon_id = team.get("hackathon_id")
        self._ensure_user_not_in_accepted_team(user_id, hackathon_id)

        membership_rows = (
            supabase.table("team_members")
            .select("id, status")
            .eq("team_id", team_id)
            .eq("user_id", user_id)
            .execute()
            .data
            or []
        )
        if membership_rows:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You already requested to join this team.",
            )

        accepted_count = self._accepted_member_count(team_id)
        max_members = team.get("max_members")
        if max_members is not None and accepted_count >= int(max_members):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Team is already full.",
            )

        try:
            inserted_rows = (
                supabase.table("team_members")
                .insert(
                    {
                        "team_id": team_id,
                        "user_id": user_id,
                        "role": "member",
                        "status": "pending",
                    }
                )
                .execute()
                .data
                or []
            )
        except Exception as exc:
            message = str(exc).lower()
            if "duplicate" in message or "unique" in message:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="You already requested to join this team.",
                ) from exc
            raise
        if not inserted_rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create join request.",
            )

        self._notify_team_leader_on_join_request(
            leader_user_id=team["creator_id"],
            team_name=team.get("name") or "team",
            requester_user_id=user_id,
            team_id=team_id,
        )
        self._invalidate_recommendations_cache_for_hackathon(hackathon_id)

        return {
            "team_member_id": inserted_rows[0]["id"],
            "message": "Join request submitted.",
        }

    def list_user_teams(self, user_id: str, hackathon_id: str | None = None) -> list[dict]:
        query = (
            supabase.table("team_members")
            .select(
                "team_id, status, teams!inner(id,hackathon_id,creator_id,name,description,required_skills,max_members,commitment_level,availability,created_at)"
            )
            .eq("user_id", user_id)
            .eq("status", "accepted")
        )
        if hackathon_id:
            query = query.eq("teams.hackathon_id", hackathon_id)

        memberships = query.execute().data or []
        if not memberships:
            return []

        teams: list[dict] = []
        team_ids: list[str] = []
        for row in memberships:
            team = row.get("teams")
            if not isinstance(team, dict):
                continue
            team_id = str(team.get("id"))
            if not team_id:
                continue
            team_ids.append(team_id)
            teams.append(team)

        if not team_ids:
            return []

        accepted_member_rows = (
            supabase.table("team_members")
            .select("team_id")
            .in_("team_id", team_ids)
            .eq("status", "accepted")
            .execute()
            .data
            or []
        )
        counts: dict[str, int] = {}
        for row in accepted_member_rows:
            tid = str(row.get("team_id"))
            if not tid:
                continue
            counts[tid] = counts.get(tid, 0) + 1

        normalized: list[dict] = []
        for team in teams:
            team_id = str(team.get("id"))
            normalized.append({**team, "members_count": counts.get(team_id, 0)})
        return normalized

    def accept_request(self, requester_user_id: str, team_member_id: str) -> dict:
        membership = self._get_membership_record(team_member_id)
        if membership.get("status") != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only pending requests can be accepted.",
            )
        team = self._get_team(membership["team_id"])
        self._ensure_team_leader(requester_user_id, team)

        accepted_count = self._accepted_member_count(membership["team_id"])
        max_members = team.get("max_members")
        if max_members is not None and membership.get("status") != "accepted" and accepted_count >= int(
            max_members
        ):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Team is already full.",
            )

        try:
            updated_rows = (
                supabase.table("team_members")
                .update({"status": "accepted"})
                .eq("id", team_member_id)
                .eq("status", "pending")
                .execute()
                .data
                or []
            )
        except Exception as exc:
            message = str(exc).lower()
            if "capacity" in message or "full" in message:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Team is already full.",
                ) from exc
            raise
        if not updated_rows:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Request was already processed.",
            )

        if membership.get("user_id") and membership.get("user_id") != requester_user_id:
            self._notifications.create_notification_safely(
                NotificationCreateInternal(
                    user_id=membership["user_id"],
                    type="team_request_accepted",
                    message=f'Your join request for team "{team.get("name") or "team"}" was accepted.',
                    reference_id=membership["team_id"],
                )
            )
            self._gamification.award_team_join_xp(
                user_id=membership["user_id"],
                team_id=membership["team_id"],
            )

        self._invalidate_recommendations_cache_for_hackathon(team.get("hackathon_id"))
        return {"message": "Request accepted."}

    def reject_request(self, requester_user_id: str, team_member_id: str) -> dict:
        membership = self._get_membership_record(team_member_id)
        if membership.get("status") != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only pending requests can be rejected.",
            )
        team = self._get_team(membership["team_id"])
        self._ensure_team_leader(requester_user_id, team)

        updated_rows = (
            supabase.table("team_members")
            .update({"status": "rejected"})
            .eq("id", team_member_id)
            .eq("status", "pending")
            .execute()
            .data
            or []
        )
        if not updated_rows:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Request was already processed.",
            )

        if membership.get("user_id") and membership.get("user_id") != requester_user_id:
            self._notifications.create_notification_safely(
                NotificationCreateInternal(
                    user_id=membership["user_id"],
                    type="team_request_rejected",
                    message=f'Your join request for team "{team.get("name") or "team"}" was rejected.',
                    reference_id=membership["team_id"],
                )
            )

        self._invalidate_recommendations_cache_for_hackathon(team.get("hackathon_id"))
        return {"message": "Request rejected."}

    def _ensure_user_not_in_accepted_team(self, user_id: str, hackathon_id: str) -> None:
        rows = (
            supabase.table("team_members")
            .select("id, team_id, teams!inner(hackathon_id)")
            .eq("user_id", user_id)
            .eq("status", "accepted")
            .eq("teams.hackathon_id", hackathon_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if rows:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You are already in a team for this hackathon",
            )

    def _get_team(self, team_id: str) -> dict:
        rows = (
            supabase.table("teams")
            .select("id, hackathon_id, creator_id, name, required_skills, max_members")
            .eq("id", team_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid team_id.",
            )
        return rows[0]

    def _accepted_member_count(self, team_id: str) -> int:
        rows = (
            supabase.table("team_members")
            .select("id")
            .eq("team_id", team_id)
            .eq("status", "accepted")
            .execute()
            .data
            or []
        )
        return len(rows)

    def _get_membership_record(self, team_member_id: str) -> dict:
        rows = (
            supabase.table("team_members")
            .select("id, team_id, user_id, status")
            .eq("id", team_member_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid team_member_id.",
            )
        return rows[0]

    def _ensure_team_leader(self, requester_user_id: str, team: dict) -> None:
        if team.get("creator_id") != requester_user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the team leader can perform this action.",
            )

    def _notify_team_leader_on_join_request(
        self,
        leader_user_id: str,
        team_name: str,
        requester_user_id: str,
        team_id: str,
    ) -> None:
        self._notifications.create_notification_safely(
            NotificationCreateInternal(
                user_id=leader_user_id,
                type="team_join_request",
                message=f"New join request from user {requester_user_id} for team {team_name}.",
                reference_id=team_id,
            )
        )

    def _invalidate_recommendations_cache_for_hackathon(self, hackathon_id: str | None) -> None:
        if not hackathon_id:
            return
        cache.invalidate_prefix(f"teams:recommend:{hackathon_id}:")
