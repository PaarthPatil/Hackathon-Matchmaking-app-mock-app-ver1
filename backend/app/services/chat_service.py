from __future__ import annotations

import logging

from fastapi import HTTPException, status

from app.db.supabase_client import supabase
from app.schemas.chat import SendMessageRequest

logger = logging.getLogger(__name__)


class ChatService:
    def send_message(self, user_id: str, payload: SendMessageRequest) -> dict:
        team_id = str(payload.team_id)
        self._ensure_accepted_team_member(user_id=user_id, team_id=team_id)

        rows = (
            supabase.table("messages")
            .insert(
                {
                    "team_id": team_id,
                    "sender_id": user_id,
                    "content": payload.content,
                }
            )
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send message.",
            )

        message_row = rows[0]
        return {"message": "Message sent.", "message_id": message_row["id"]}

    def can_access_team_chat(self, user_id: str, team_id: str) -> bool:
        self._ensure_accepted_team_member(user_id=user_id, team_id=team_id)
        return True

    def list_messages(self, user_id: str, team_id: str, limit: int, offset: int) -> list[dict]:
        self._ensure_accepted_team_member(user_id=user_id, team_id=team_id)
        rows = (
            supabase.table("messages")
            .select("id,team_id,sender_id,content,created_at,profiles:sender_id(id,username,name,avatar_url)")
            .eq("team_id", team_id)
            .order("created_at", desc=False)
            .range(offset, offset + limit - 1)
            .execute()
            .data
            or []
        )
        logger.info(
            "Chat messages loaded | user_id=%s team_id=%s count=%s",
            user_id,
            team_id,
            len(rows),
        )
        return rows

    def _ensure_accepted_team_member(self, user_id: str, team_id: str) -> None:
        rows = (
            supabase.table("team_members")
            .select("id")
            .eq("team_id", team_id)
            .eq("user_id", user_id)
            .eq("status", "accepted")
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only accepted team members can send messages.",
            )
