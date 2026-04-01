from __future__ import annotations

from uuid import uuid4
from typing import Any

from fastapi import HTTPException, status

from app.db.supabase_client import supabase


class GamificationService:
    def award_profile_completion_xp(self, user_id: str) -> dict[str, Any]:
        return self._award_xp_event(
            user_id=user_id,
            event_type="profile_completed",
            reference_id="self",
            xp_delta=50,
        )

    def award_team_join_xp(self, user_id: str, team_id: str) -> dict[str, Any]:
        return self._award_xp_event(
            user_id=user_id,
            event_type="team_join_accepted",
            reference_id=team_id,
            xp_delta=30,
        )

    def award_post_creation_xp(self, user_id: str, post_id: str) -> dict[str, Any]:
        return self._award_xp_event(
            user_id=user_id,
            event_type="post_created",
            reference_id=post_id,
            xp_delta=10,
        )

    def award_manual_xp(self, user_id: str, xp_delta: int) -> dict[str, Any]:
        return self._award_xp_event(
            user_id=user_id,
            event_type="manual_reward",
            reference_id=f"manual:{uuid4()}",
            xp_delta=xp_delta,
        )

    def _award_xp_event(
        self,
        user_id: str,
        event_type: str,
        reference_id: str,
        xp_delta: int,
    ) -> dict[str, Any]:
        try:
            response = supabase.rpc(
                "award_xp_event",
                {
                    "p_user_id": user_id,
                    "p_event_type": event_type,
                    "p_reference_id": reference_id,
                    "p_xp_delta": xp_delta,
                },
            ).execute()
            data = response.data or []
            if data and isinstance(data[0], dict):
                return data[0]
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="XP service returned an unexpected response.",
            )
        except HTTPException:
            raise
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="XP service is unavailable. Ensure SQL migration 002_social_layer.sql is applied.",
            ) from exc
