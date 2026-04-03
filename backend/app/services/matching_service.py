from __future__ import annotations

from fastapi import HTTPException, status

from app.core.cache import cache
from app.db.supabase_client import supabase
from app.schemas.team import RecommendationResponse
from app.services.profile_service import ProfileService


class MatchingService:
    def __init__(self) -> None:
        self._profiles = ProfileService()

    def recommend_teams(
        self,
        user_id: str,
        hackathon_id: str,
        force_refresh: bool = False,
    ) -> list[RecommendationResponse]:
        cache_key = f"teams:recommend:{hackathon_id}:{user_id}"
        if not force_refresh:
            cached = cache.get(cache_key)
            if isinstance(cached, list):
                return [RecommendationResponse.model_validate(item) for item in cached]

        self._ensure_user_not_in_accepted_team(user_id, hackathon_id)

        profile = self._get_profile(user_id)
        user_skills = self._normalize_skills(profile.get("skills"))

        teams = (
            supabase.table("teams")
            .select("id, name, creator_id, required_skills, max_members")
            .eq("hackathon_id", hackathon_id)
            .execute()
            .data
            or []
        )
        if not teams:
            return []

        team_ids = [team["id"] for team in teams]

        accepted_members = (
            supabase.table("team_members")
            .select("team_id, user_id")
            .in_("team_id", team_ids)
            .eq("status", "accepted")
            .execute()
            .data
            or []
        )
        user_memberships = (
            supabase.table("team_members")
            .select("team_id, status")
            .eq("user_id", user_id)
            .in_("team_id", team_ids)
            .execute()
            .data
            or []
        )

        profile_ids = sorted({row["user_id"] for row in accepted_members if row.get("user_id")})
        member_profiles: dict[str, dict] = {}
        if profile_ids:
            profile_rows = (
                supabase.table("profiles")
                .select("id, skills")
                .in_("id", profile_ids)
                .execute()
                .data
                or []
            )
            member_profiles = {row["id"]: row for row in profile_rows}

        user_status_by_team = {row["team_id"]: row["status"] for row in user_memberships}

        accepted_members_by_team: dict[str, list[dict]] = {}
        for row in accepted_members:
            accepted_members_by_team.setdefault(row["team_id"], []).append(row)

        results: list[RecommendationResponse] = []
        for team in teams:
            team_id = team["id"]
            if team.get("creator_id") == user_id:
                continue

            membership_status = user_status_by_team.get(team_id)
            if membership_status in {"pending", "rejected", "accepted"}:
                continue

            team_accepted_members = accepted_members_by_team.get(team_id, [])
            members_count = len(team_accepted_members)
            max_members = team.get("max_members")
            if max_members is not None and members_count >= int(max_members):
                continue

            required_skills = self._normalize_skills(team.get("required_skills"))
            current_team_skills: set[str] = set()

            for member in team_accepted_members:
                member_profile = member_profiles.get(member["user_id"])
                if not member_profile:
                    continue
                current_team_skills.update(self._normalize_skills(member_profile.get("skills")))

            matching_skills = user_skills.intersection(required_skills)
            missing_roles = required_skills - current_team_skills
            filled_missing_roles = user_skills.intersection(missing_roles)

            if required_skills:
                skill_score = (len(matching_skills) / len(required_skills)) * 100
                role_score = (
                    (len(filled_missing_roles) / len(missing_roles)) * 100
                    if missing_roles
                    else 70.0
                )
            else:
                # Teams with no required skills should still be shown as fallback options.
                skill_score = 35.0
                role_score = 35.0

            final_score = max(0.0, min(100.0, (skill_score * 0.7) + (role_score * 0.3)))

            if required_skills:
                if filled_missing_roles:
                    highlighted_role = next(iter(filled_missing_roles))
                    explanation = (
                        f"You match {len(matching_skills)}/{len(required_skills)} required skills and "
                        f"help cover missing role {highlighted_role}."
                    )
                else:
                    explanation = (
                        f"You match {len(matching_skills)}/{len(required_skills)} required skills. "
                        "Shown as a compatibility fallback option."
                    )
            else:
                explanation = "Team has open spots and no required skills listed. Shown as a fallback option."

            results.append(
                RecommendationResponse(
                    team_id=team_id,
                    team_name=team.get("name") or "Unnamed Team",
                    members_count=members_count,
                    compatibility_score=round(final_score, 2),
                    explanation=explanation,
                )
            )

        results.sort(key=lambda item: item.compatibility_score, reverse=True)
        cache.set(
            cache_key,
            [item.model_dump() for item in results],
            ttl_seconds=60,
        )
        return results

    def _get_profile(self, user_id: str) -> dict:
        profile = self._profiles.get_profile(user_id=user_id)
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found.",
            )
        return profile

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

    def _normalize_skills(self, value: object) -> set[str]:
        if not isinstance(value, list):
            return set()
        normalized = {
            str(skill).strip().lower()
            for skill in value
            if isinstance(skill, str) and skill.strip()
        }
        return normalized
