from __future__ import annotations

import logging

from fastapi import HTTPException, status

from app.db.supabase_client import supabase
from app.schemas.notification import NotificationCreateInternal, NotificationResponse

logger = logging.getLogger(__name__)


class NotificationService:
    def create_notification(self, payload: NotificationCreateInternal) -> dict:
        rows = (
            supabase.table("notifications")
            .insert(payload.model_dump())
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create notification.",
            )
        return rows[0]

    def create_notification_safely(self, payload: NotificationCreateInternal) -> None:
        try:
            self.create_notification(payload)
        except Exception:
            logger.exception(
                "Failed to create notification | recipient=%s type=%s",
                payload.user_id,
                payload.type,
            )
            return

    def list_notifications(
        self,
        user_id: str,
        unread_only: bool = False,
        limit: int = 50,
        offset: int = 0,
    ) -> list[NotificationResponse]:
        query = (
            supabase.table("notifications")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
        )
        if unread_only:
            query = query.eq("read", False)

        rows = query.range(offset, offset + limit - 1).execute().data or []
        return [NotificationResponse.model_validate(row) for row in rows]

    def mark_as_read(self, user_id: str, notification_id: str) -> dict:
        existing = (
            supabase.table("notifications")
            .select("id")
            .eq("id", notification_id)
            .eq("user_id", user_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notification not found.",
            )

        (
            supabase.table("notifications")
            .update({"read": True})
            .eq("id", notification_id)
            .eq("user_id", user_id)
            .execute()
        )
        return {"message": "Notification marked as read."}

    def mark_all_as_read(self, user_id: str) -> dict:
        supabase.table("notifications").update({"read": True}).eq("user_id", user_id).eq(
            "read", False
        ).execute()
        return {"message": "All notifications marked as read."}

    def delete_notification(self, user_id: str, notification_id: str) -> dict:
        existing = (
            supabase.table("notifications")
            .select("id")
            .eq("id", notification_id)
            .eq("user_id", user_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notification not found.",
            )

        supabase.table("notifications").delete().eq("id", notification_id).eq(
            "user_id", user_id
        ).execute()
        return {"message": "Notification deleted."}
