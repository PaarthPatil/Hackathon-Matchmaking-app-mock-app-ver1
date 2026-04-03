from __future__ import annotations

import re
from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

from fastapi import HTTPException, status

from app.core.config import settings
from app.db.supabase_client import supabase
from app.schemas.admin import (
    AdminActivityItem,
    AdminCreateTeamRequest,
    AdminCreateUserRequest,
    AdminSeedMockDataRequest,
    AdminTriggerEventsRequest,
)
from app.schemas.chat import SendMessageRequest
from app.schemas.community import CreateCommentRequest, CreatePostRequest
from app.schemas.notification import NotificationCreateInternal
from app.services.chat_service import ChatService
from app.services.community_service import CommunityService
from app.services.notification_service import NotificationService
from app.services.team_service import TeamService


class AdminControlService:
    _MISSING_COLUMN_REGEX = re.compile(r'column "([^"]+)" of relation "profiles" does not exist')

    def __init__(self) -> None:
        self._notifications = NotificationService()
        self._community = CommunityService()
        self._teams = TeamService()
        self._chat = ChatService()

    def list_users(self, limit: int, offset: int) -> dict:
        response = (
            supabase.table("profiles")
            .select("*", count="exact")
            .order("created_at", desc=True)
            .range(offset, offset + limit - 1)
            .execute()
        )
        rows = response.data or []
        items = [
            {
                "id": row.get("id"),
                "username": row.get("username"),
                "name": row.get("name"),
                "bio": row.get("bio"),
                "role": self._extract_role(row),
                "skills": row.get("skills") if isinstance(row.get("skills"), list) else [],
                "tech_stack": row.get("tech_stack")
                if isinstance(row.get("tech_stack"), list)
                else [],
                "experience_level": row.get("experience_level"),
                "looking_for_team": bool(row.get("looking_for_team", False)),
                "created_at": row.get("created_at"),
            }
            for row in rows
        ]
        return {"items": items, "limit": limit, "offset": offset, "total": int(response.count or 0)}

    def get_admin_catalog(self) -> dict:
        hackathons = (
            supabase.table("hackathons")
            .select("id,title,start_date,end_date,mode,organizer,max_team_size")
            .order("start_date", desc=False)
            .limit(200)
            .execute()
            .data
            or []
        )
        users = (
            supabase.table("profiles")
            .select("id,username,name")
            .order("created_at", desc=True)
            .limit(300)
            .execute()
            .data
            or []
        )
        teams = (
            supabase.table("teams")
            .select("id,name,hackathon_id,creator_id,max_members,created_at")
            .order("created_at", desc=True)
            .limit(300)
            .execute()
            .data
            or []
        )
        return {"hackathons": hackathons, "users": users, "teams": teams}

    def create_user(self, payload: AdminCreateUserRequest) -> dict:
        self._require_service_role()
        try:
            response = supabase.auth.admin.create_user(
                {
                    "email": payload.email,
                    "password": payload.password,
                    "email_confirm": True,
                    "user_metadata": {"full_name": payload.name},
                }
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to create auth user: {exc}",
            ) from exc

        user = getattr(response, "user", None)
        user_id = getattr(user, "id", None)
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Auth user creation returned no user id.",
            )

        profile_payload: dict[str, object] = {
            "id": str(user_id),
            "username": payload.username,
            "name": payload.name,
            "bio": payload.bio or "",
            "skills": payload.skills,
            "tech_stack": payload.tech_stack,
            "experience_level": payload.experience_level,
            "looking_for_team": payload.looking_for_team,
            "xp": 0,
            "level": 1,
            "role": payload.role,
            "roles": [payload.role],
        }
        profile_row = self._upsert_profile_row(profile_payload)
        return {
            "message": "User created successfully.",
            "user_id": str(user_id),
            "profile": profile_row,
        }

    def create_team(self, payload: AdminCreateTeamRequest) -> dict:
        self._require_service_role()
        hackathon_id = str(payload.hackathon_id)
        creator_id = str(payload.creator_user_id)

        self._ensure_profile_exists(creator_id)
        self._ensure_hackathon_exists(hackathon_id)

        created_rows = (
            supabase.table("teams")
            .insert(
                {
                    "hackathon_id": hackathon_id,
                    "creator_id": creator_id,
                    "name": payload.name,
                    "description": payload.description,
                    "required_skills": payload.required_skills,
                    "max_members": payload.max_members,
                    "commitment_level": payload.commitment_level,
                    "availability": payload.availability,
                }
            )
            .execute()
            .data
            or []
        )
        if not created_rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create team.",
            )

        team_row = created_rows[0]
        try:
            supabase.table("team_members").insert(
                {
                    "team_id": team_row["id"],
                    "user_id": creator_id,
                    "role": "leader",
                    "status": "accepted",
                }
            ).execute()
        except Exception:
            # Best-effort leader membership. Team still created.
            pass

        return {"message": "Team created successfully.", "team_id": team_row["id"]}

    def seed_mock_data(self, payload: AdminSeedMockDataRequest) -> dict:
        self._require_service_role()
        now = datetime.now(timezone.utc)
        created_users: list[str] = []
        created_hackathons: list[str] = []
        created_teams: list[str] = []

        for index in range(payload.user_count):
            stamp = int(now.timestamp())
            email = f"mock{stamp}_{index}@catalyst.test"
            username = f"mock_{stamp}_{index}"
            try:
                result = self.create_user(
                    AdminCreateUserRequest(
                        email=email,
                        password="mockpass123",
                        username=username,
                        name=f"Mock User {index + 1}",
                        bio="Generated by admin mock seeder.",
                        role="user",
                        skills=["Flutter", "Python"] if index % 2 == 0 else ["Design", "Product"],
                        tech_stack=["Supabase", "FastAPI"],
                        experience_level="intermediate",
                        looking_for_team=True,
                    )
                )
                created_users.append(result["user_id"])
            except Exception:
                continue

        for index in range(payload.hackathon_count):
            start = now + timedelta(days=7 + (index * 5))
            end = start + timedelta(days=2)
            rows = (
                supabase.table("hackathons")
                .insert(
                    {
                        "title": f"Admin Mock Hackathon {index + 1}",
                        "description": "Auto-generated for admin testing workflows.",
                        "organizer": "Catalyst Admin",
                        "start_date": start.isoformat(),
                        "end_date": end.isoformat(),
                        "mode": "online",
                        "location": "Global",
                        "prize_pool": "$5,000",
                        "max_team_size": 5,
                        "tags": ["mock", "admin", "testing"],
                    }
                )
                .execute()
                .data
                or []
            )
            if rows:
                created_hackathons.append(rows[0]["id"])

        if created_users and created_hackathons:
            for hackathon_id in created_hackathons:
                for team_index in range(payload.teams_per_hackathon):
                    creator_id = created_users[(team_index + len(created_teams)) % len(created_users)]
                    try:
                        team = self.create_team(
                            AdminCreateTeamRequest(
                                hackathon_id=UUID(hackathon_id),
                                creator_user_id=UUID(creator_id),
                                name=f"Mock Team {team_index + 1}",
                                description="Auto-generated team for admin testing.",
                                required_skills=["flutter", "backend"],
                                max_members=5,
                                commitment_level="medium",
                                availability="weeknights",
                            )
                        )
                        created_teams.append(team["team_id"])
                    except Exception:
                        continue

        if payload.include_social_feed and created_users:
            for idx, user_id in enumerate(created_users[: min(10, len(created_users))]):
                try:
                    self._community.create_post(
                        user_id=user_id,
                        payload=CreatePostRequest(
                            content=f"Admin-seeded mock post #{idx + 1}",
                            image_url=None,
                        ),
                    )
                except Exception:
                    continue

        return {
            "message": "Mock data seed completed.",
            "created_users": len(created_users),
            "created_hackathons": len(created_hackathons),
            "created_teams": len(created_teams),
        }

    def trigger_test_events(
        self,
        admin_user_id: str,
        payload: AdminTriggerEventsRequest,
    ) -> dict:
        self._require_service_role()
        activities: list[AdminActivityItem] = []

        target_user_id = str(payload.target_user_id) if payload.target_user_id else self._pick_target_user_id()
        if not target_user_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No target user available to trigger test events.",
            )

        target_post_id = str(payload.target_post_id) if payload.target_post_id else None
        target_team_id = str(payload.target_team_id) if payload.target_team_id else None
        message = payload.message or "Admin-triggered test event."

        if payload.create_notification:
            try:
                self._notifications.create_notification_safely(
                    NotificationCreateInternal(
                        user_id=target_user_id,
                        type="admin_test_notification",
                        message=message,
                        reference_id=None,
                    )
                )
                activities.append(
                    AdminActivityItem(
                        event="notification",
                        status="success",
                        details="Created test notification.",
                    )
                )
            except Exception as exc:
                activities.append(
                    AdminActivityItem(
                        event="notification",
                        status="failed",
                        details=f"Failed to create notification: {exc}",
                    )
                )

        if payload.create_post:
            try:
                post_result = self._community.create_post(
                    user_id=target_user_id,
                    payload=CreatePostRequest(content=message, image_url=None),
                )
                target_post_id = post_result.get("post_id")
                activities.append(
                    AdminActivityItem(
                        event="post",
                        status="success",
                        details="Created test community post.",
                        reference_id=target_post_id,
                    )
                )
            except Exception as exc:
                activities.append(
                    AdminActivityItem(
                        event="post",
                        status="failed",
                        details=f"Failed to create test post: {exc}",
                    )
                )

        if payload.create_comment:
            if not target_post_id:
                target_post_id = self._pick_latest_post_id()
            if target_post_id:
                try:
                    comment_result = self._community.create_comment(
                        user_id=admin_user_id,
                        payload=CreateCommentRequest(
                            post_id=UUID(target_post_id),
                            content="Admin test comment.",
                        ),
                    )
                    activities.append(
                        AdminActivityItem(
                            event="comment",
                            status="success",
                            details="Created test comment.",
                            reference_id=comment_result.get("comment_id"),
                        )
                    )
                except Exception as exc:
                    activities.append(
                        AdminActivityItem(
                            event="comment",
                            status="failed",
                            details=f"Failed to create comment: {exc}",
                        )
                    )
            else:
                activities.append(
                    AdminActivityItem(
                        event="comment",
                        status="skipped",
                        details="No post available for comment event.",
                    )
                )

        if payload.create_join_request:
            if not target_team_id:
                target_team_id = self._pick_available_team_id()
            if target_team_id:
                try:
                    join_result = self._teams.join_team(user_id=target_user_id, team_id=target_team_id)
                    activities.append(
                        AdminActivityItem(
                            event="join_request",
                            status="success",
                            details=join_result.get("message", "Join request submitted."),
                            reference_id=str(join_result.get("team_member_id") or ""),
                        )
                    )
                except Exception as exc:
                    activities.append(
                        AdminActivityItem(
                            event="join_request",
                            status="failed",
                            details=f"Failed to create join request: {exc}",
                        )
                    )
            else:
                activities.append(
                    AdminActivityItem(
                        event="join_request",
                        status="skipped",
                        details="No available team found.",
                    )
                )

        if payload.create_chat_message:
            accepted_team_id = self._pick_accepted_team_for_user(target_user_id)
            if accepted_team_id:
                try:
                    chat_result = self._chat.send_message(
                        user_id=target_user_id,
                        payload=SendMessageRequest(
                            team_id=UUID(accepted_team_id),
                            content="Admin-triggered test chat message.",
                        ),
                    )
                    activities.append(
                        AdminActivityItem(
                            event="chat_message",
                            status="success",
                            details=chat_result.get("message", "Message sent."),
                            reference_id=chat_result.get("message_id"),
                        )
                    )
                except Exception as exc:
                    activities.append(
                        AdminActivityItem(
                            event="chat_message",
                            status="failed",
                            details=f"Failed to send chat message: {exc}",
                        )
                    )
            else:
                activities.append(
                    AdminActivityItem(
                        event="chat_message",
                        status="skipped",
                        details="Target user is not an accepted member of any team.",
                    )
                )

        success_count = len([item for item in activities if item.status == "success"])
        failed_count = len([item for item in activities if item.status == "failed"])
        skipped_count = len([item for item in activities if item.status == "skipped"])
        return {
            "summary": {
                "success": success_count,
                "failed": failed_count,
                "skipped": skipped_count,
                "target_user_id": target_user_id,
            },
            "activities": [item.model_dump(mode="json") for item in activities],
        }

    def _extract_role(self, profile: dict) -> str:
        role_value = profile.get("role")
        if isinstance(role_value, str) and role_value.strip():
            return role_value.strip().lower()

        roles_value = profile.get("roles")
        if isinstance(roles_value, list):
            normalized = {
                str(item).strip().lower()
                for item in roles_value
                if isinstance(item, str) and item.strip()
            }
            if "admin" in normalized:
                return "admin"
        return "user"

    def _upsert_profile_row(self, payload: dict[str, object]) -> dict:
        working = payload.copy()
        username_base = str(payload.get("username") or f"user_{uuid4().hex[:8]}")
        attempt = 0
        while working:
            attempt += 1
            if attempt > 5:
                break
            try:
                rows = (
                    supabase.table("profiles")
                    .upsert(working, on_conflict="id")
                    .execute()
                    .data
                    or []
                )
                if rows:
                    return rows[0]
                read_rows = (
                    supabase.table("profiles")
                    .select("*")
                    .eq("id", str(payload["id"]))
                    .limit(1)
                    .execute()
                    .data
                    or []
                )
                if read_rows:
                    return read_rows[0]
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to upsert profile row.",
                )
            except Exception as exc:
                error_text = str(exc).lower()
                missing_column = self._extract_missing_column(str(exc))
                if missing_column and missing_column in working:
                    working.pop(missing_column)
                    continue
                if "duplicate" in error_text or "unique" in error_text:
                    working["username"] = f"{username_base}_{uuid4().hex[:4]}"
                    continue
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail=f"Failed to create profile row: {exc}",
                ) from exc

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create profile with available schema columns.",
        )

    def _extract_missing_column(self, error_message: str) -> str | None:
        match = self._MISSING_COLUMN_REGEX.search(error_message)
        if not match:
            return None
        return match.group(1)

    def _ensure_profile_exists(self, user_id: str) -> None:
        rows = (
            supabase.table("profiles")
            .select("id")
            .eq("id", user_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Creator profile not found.",
            )

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
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Hackathon not found.",
            )

    def _pick_target_user_id(self) -> str | None:
        rows = (
            supabase.table("profiles")
            .select("id")
            .order("created_at", desc=False)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            return None
        return str(rows[0].get("id"))

    def _pick_latest_post_id(self) -> str | None:
        rows = (
            supabase.table("posts")
            .select("id")
            .order("created_at", desc=True)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            return None
        return str(rows[0].get("id"))

    def _pick_available_team_id(self) -> str | None:
        rows = (
            supabase.table("teams")
            .select("id")
            .order("created_at", desc=False)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            return None
        return str(rows[0].get("id"))

    def _pick_accepted_team_for_user(self, user_id: str) -> str | None:
        rows = (
            supabase.table("team_members")
            .select("team_id")
            .eq("user_id", user_id)
            .eq("status", "accepted")
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            return None
        return str(rows[0].get("team_id"))

    def _require_service_role(self) -> None:
        if settings.has_service_role_key:
            return
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Admin write actions require SUPABASE_SERVICE_ROLE_KEY configured "
                "with role=service_role."
            ),
        )
