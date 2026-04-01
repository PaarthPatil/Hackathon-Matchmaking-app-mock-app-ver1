from __future__ import annotations

from fastapi import HTTPException, status

from app.db.supabase_client import supabase
from app.schemas.chat import SendMessageRequest


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
