from __future__ import annotations

import re

from fastapi import HTTPException, status

from app.db.supabase_client import supabase
from app.schemas.profile import ProfileUpdateRequest


class ProfileService:
    _MISSING_COLUMN_REGEX = re.compile(r'column "([^"]+)" of relation "profiles" does not exist')

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
