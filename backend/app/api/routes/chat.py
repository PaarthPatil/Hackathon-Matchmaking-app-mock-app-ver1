from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.core.dependencies import get_current_user
from app.schemas.chat import SendMessageRequest
from app.services.chat_service import ChatService

router = APIRouter(prefix="/chat", tags=["chat"], dependencies=[Depends(get_current_user)])
chat_service = ChatService()


@router.get("/health")
def chat_health():
    return {"status": "ok"}


@router.post("/send")
def send_message(payload: SendMessageRequest, current_user: dict = Depends(get_current_user)):
    return chat_service.send_message(user_id=current_user["user_id"], payload=payload)


@router.get("/access")
def check_chat_access(team_id: UUID, current_user: dict = Depends(get_current_user)):
    allowed = chat_service.can_access_team_chat(
        user_id=current_user["user_id"],
        team_id=str(team_id),
    )
    return {"allowed": allowed}


@router.get("/messages")
def list_messages(
    team_id: UUID,
    limit: int = Query(default=100, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    return chat_service.list_messages(
        user_id=current_user["user_id"],
        team_id=str(team_id),
        limit=limit,
        offset=offset,
    )
