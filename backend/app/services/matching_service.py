from __future__ import annotations

from fastapi import HTTPException, status

from app.core.cache import cache
from app.db.supabase_client import supabase
from app.schemas.team import RecommendationResponse


class MatchingService:
    _EXPERIENCE_MAP = {
        "beginner": 1,
        "intermediate": 2,
        "advanced": 3,
    }

    def recommend_teams(self, user_id: str, hackathon_id: str) -> list[RecommendationResponse]:
        cache_key = f"teams:recommend:{hackathon_id}:{user_id}"
        cached = cache.get(cache_key)
        if isinstance(cached, list):
            return [RecommendationResponse.model_validate(item) for item in cached]

        self._ensure_user_not_in_accepted_team(user_id, hackathon_id)

        profile = self._get_profile(user_id)
        user_skills = self._normalize_skills(profile.get("skills"))
        user_exp = self._exp_to_num(profile.get("experience_level"))

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
                .select("id, skills, experience_level")
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
            member_exp_values: list[int] = []

            for member in team_accepted_members:
                member_profile = member_profiles.get(member["user_id"])
                if not member_profile:
                    continue
                current_team_skills.update(self._normalize_skills(member_profile.get("skills")))
                member_exp_values.append(self._exp_to_num(member_profile.get("experience_level")))

            matching_skills = user_skills.intersection(required_skills)
            skill_score = (
                (len(matching_skills) / len(required_skills)) * 100 if required_skills else 0.0
            )

            missing_roles = required_skills - current_team_skills
            filled_missing_roles = user_skills.intersection(missing_roles)
            role_score = 100.0 if filled_missing_roles else 40.0

            if member_exp_values:
                team_avg_exp = sum(member_exp_values) / len(member_exp_values)
            else:
                team_avg_exp = float(user_exp)

            experience_score = 100 - abs(float(user_exp) - float(team_avg_exp)) * 30
            experience_score = max(0.0, min(100.0, experience_score))

            final_score = (skill_score * 0.5) + (role_score * 0.3) + (experience_score * 0.2)

            missing_role = next(iter(filled_missing_roles or missing_roles), "role")
            explanation = (
                f"You match {len(matching_skills)}/{len(required_skills)} required skills and fill a "
                f"missing {missing_role}. Your experience aligns well with the team."
            )

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
        rows = (
            supabase.table("profiles")
            .select("id, skills, experience_level")
            .eq("id", user_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found.",
            )
        return rows[0]

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

    def _exp_to_num(self, value: object) -> int:
        if not isinstance(value, str):
            return self._EXPERIENCE_MAP["intermediate"]
        return self._EXPERIENCE_MAP.get(value.strip().lower(), self._EXPERIENCE_MAP["intermediate"])
