from fastapi import APIRouter, Depends, Query

from app.core.dependencies import get_current_user
from app.schemas.notification import (
    NotificationCreateInternal,
    NotificationCreateRequest,
    NotificationDeleteRequest,
    NotificationReadRequest,
    NotificationResponse,
)
from app.services.notification_service import NotificationService

router = APIRouter(prefix="/notifications", tags=["notifications"], dependencies=[Depends(get_current_user)])
notification_service = NotificationService()


@router.get("/health")
def notification_health():
    return {"status": "ok"}


@router.get("", response_model=list[NotificationResponse])
def list_notifications(
    current_user: dict = Depends(get_current_user),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    return notification_service.list_notifications(
        user_id=current_user["user_id"],
        unread_only=False,
        limit=limit,
        offset=offset,
    )


@router.get("/unread", response_model=list[NotificationResponse])
def list_unread_notifications(
    current_user: dict = Depends(get_current_user),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    return notification_service.list_notifications(
        user_id=current_user["user_id"],
        unread_only=True,
        limit=limit,
        offset=offset,
    )


@router.post("/mark_read")
def mark_notification_read(
    payload: NotificationReadRequest,
    current_user: dict = Depends(get_current_user),
):
    return notification_service.mark_as_read(
        user_id=current_user["user_id"],
        notification_id=str(payload.id),
    )


@router.post("/mark_all_read")
def mark_all_notifications_read(current_user: dict = Depends(get_current_user)):
    return notification_service.mark_all_as_read(user_id=current_user["user_id"])


@router.post("/delete")
def delete_notification(
    payload: NotificationDeleteRequest,
    current_user: dict = Depends(get_current_user),
):
    return notification_service.delete_notification(
        user_id=current_user["user_id"],
        notification_id=str(payload.id),
    )


@router.post("/create")
def create_notification(
    payload: NotificationCreateRequest,
    current_user: dict = Depends(get_current_user),
):
    notification = notification_service.create_notification(
        NotificationCreateInternal(
            user_id=current_user["user_id"],
            type=payload.type,
            message=payload.message,
            reference_id=str(payload.reference_id) if payload.reference_id else None,
        )
    )
    return {"message": "Notification created.", "id": notification["id"]}
