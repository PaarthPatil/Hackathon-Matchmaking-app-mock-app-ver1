from fastapi import APIRouter, Depends

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
