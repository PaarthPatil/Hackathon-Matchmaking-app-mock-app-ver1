from __future__ import annotations

import re
import logging

from fastapi import HTTPException, status

from app.db.supabase_client import supabase
from app.schemas.profile import ProfileUpdateRequest

logger = logging.getLogger(__name__)


class ProfileService:
    _MISSING_COLUMN_REGEX = re.compile(r'column "([^"]+)" of relation "profiles" does not exist')

    def get_profile(self, user_id: str) -> dict:
        rows = (
            supabase.table("profiles")
            .select("*")
            .eq("id", user_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if rows:
            logger.info("Profile loaded | user_id=%s", user_id)
            return self._normalize_profile_row(rows[0], user_id=user_id)

        created = self._create_profile_once(user_id=user_id)
        if created:
            logger.info("Profile auto-created | user_id=%s", user_id)
            return self._normalize_profile_row(created, user_id=user_id)

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create profile for authenticated user.",
        )

    def update_profile(self, user_id: str, payload: ProfileUpdateRequest) -> dict:
        requested_updates = self._build_update_payload(payload)
        if not requested_updates:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No supported profile fields provided for update.",
            )

        update_payload = requested_updates.copy()
        while update_payload:
            try:
                rows = (
                    supabase.table("profiles")
                    .update(update_payload)
                    .eq("id", user_id)
                    .execute()
                    .data
                    or []
                )
                if not rows:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail="Profile not found.",
                    )
                return {
                    "message": "Profile updated successfully.",
                    "updated_fields": sorted(update_payload.keys()),
                }
            except HTTPException:
                raise
            except Exception as exc:
                missing_column = self._extract_missing_column(str(exc))
                if missing_column and missing_column in update_payload:
                    update_payload.pop(missing_column)
                    continue
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Failed to update profile.",
                ) from exc

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No supported profile fields available in database schema.",
        )

    def update_avatar(self, user_id: str, avatar_url: str) -> dict:
        rows = (
            supabase.table("profiles")
            .update({"avatar_url": avatar_url})
            .eq("id", user_id)
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found.",
            )
        return {"message": "Avatar updated successfully.", "avatar_url": avatar_url}

    def _build_update_payload(self, payload: ProfileUpdateRequest) -> dict:
        updates: dict[str, object] = {}

        direct_fields = [
            "username",
            "name",
            "bio",
            "avatar_url",
            "skills",
            "tech_stack",
            "experience_level",
            "github",
            "linkedin",
            "portfolio",
            "looking_for_team",
        ]
        for field_name in direct_fields:
            value = getattr(payload, field_name, None)
            if value is not None:
                updates[field_name] = value

        # Support older payload fields that send links as arrays.
        link_compatibility = {
            "github": payload.github_link,
            "linkedin": payload.linkedin_link,
            "portfolio": payload.portfolio_link,
        }
        for target_field, values in link_compatibility.items():
            if target_field in updates:
                continue
            if not isinstance(values, list):
                continue
            normalized = [item.strip() for item in values if isinstance(item, str) and item.strip()]
            if normalized:
                updates[target_field] = normalized[0]

        return updates

    def _extract_missing_column(self, error_message: str) -> str | None:
        match = self._MISSING_COLUMN_REGEX.search(error_message)
        if not match:
            return None
        return match.group(1)

    def _create_profile_once(self, user_id: str) -> dict | None:
        base_username = f"user_{user_id.replace('-', '')[:8]}"
        payload: dict[str, object] = {
            "id": user_id,
            "username": base_username,
            "name": "Catalyst User",
            "bio": "",
            "skills": [],
            "tech_stack": [],
            "experience_level": "intermediate",
            "looking_for_team": True,
            "xp": 0,
            "level": 1,
            "role": "user",
            "roles": ["user"],
        }

        working = payload.copy()
        attempt = 0
        while working:
            attempt += 1
            if attempt > 5:
                return None
            try:
                inserted = (
                    supabase.table("profiles")
                    .upsert(working, on_conflict="id")
                    .execute()
                    .data
                    or []
                )
                if inserted:
                    return inserted[0]

                rows = (
                    supabase.table("profiles")
                    .select("*")
                    .eq("id", user_id)
                    .limit(1)
                    .execute()
                    .data
                    or []
                )
                return rows[0] if rows else None
            except Exception as exc:
                error_text = str(exc).lower()
                missing_column = self._extract_missing_column(str(exc))
                if missing_column and missing_column in working:
                    working.pop(missing_column)
                    continue
                if "duplicate" in error_text or "unique" in error_text:
                    working["username"] = f"{base_username}_{attempt}"
                    continue
                return None
        return None

    def _normalize_profile_row(self, row: dict, user_id: str) -> dict:
        role = row.get("role")
        roles = row.get("roles") if isinstance(row.get("roles"), list) else []
        if isinstance(role, str) and role.strip():
            normalized_role = role.strip().lower()
        else:
            normalized_role = "user"

        role_list = [
            item.strip().lower()
            for item in roles
            if isinstance(item, str) and item.strip()
        ]
        if normalized_role not in role_list:
            role_list = [normalized_role, *role_list]

        return {
            **row,
            "id": str(row.get("id") or user_id),
            "username": row.get("username") or f"user_{user_id.replace('-', '')[:8]}",
            "name": row.get("name") or "Catalyst User",
            "bio": row.get("bio") or "",
            "avatar_url": row.get("avatar_url"),
            "skills": row.get("skills") if isinstance(row.get("skills"), list) else [],
            "tech_stack": row.get("tech_stack") if isinstance(row.get("tech_stack"), list) else [],
            "github_link": [row.get("github")] if isinstance(row.get("github"), str) and row.get("github") else [],
            "linkedin_link": [row.get("linkedin")]
            if isinstance(row.get("linkedin"), str) and row.get("linkedin")
            else [],
            "portfolio_link": [row.get("portfolio")]
            if isinstance(row.get("portfolio"), str) and row.get("portfolio")
            else [],
            "hackathons_joined": int(row.get("hackathons_joined") or 0),
            "wins": int(row.get("wins") or 0),
            "teams_joined": int(row.get("teams_joined") or 0),
            "availability": row.get("availability") or "Available",
            "experience_level": row.get("experience_level") or "intermediate",
            "looking_for_team": bool(row.get("looking_for_team", True)),
            "role": normalized_role,
            "roles": role_list,
        }
