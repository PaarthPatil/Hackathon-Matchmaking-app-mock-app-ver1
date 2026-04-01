from fastapi import APIRouter, Depends, Query
from uuid import UUID

from app.core.dependencies import get_current_user
from app.schemas.hackathon import HackathonListResponse, HackathonRequestCreate
from app.services.hackathon_service import HackathonService

router = APIRouter(prefix="/hackathons", tags=["hackathons"])
hackathon_service = HackathonService()


@router.get("/health")
def hackathon_health():
    return {"status": "ok"}


@router.post("/request")
def submit_hackathon_request(
    payload: HackathonRequestCreate,
    current_user: dict = Depends(get_current_user),
):
    return hackathon_service.submit_request(user_id=current_user["user_id"], payload=payload)


@router.get("", response_model=HackathonListResponse)
def get_hackathons(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=50),
):
    return hackathon_service.list_hackathons(page=page, page_size=page_size)


@router.get("/{hackathon_id}")
def get_hackathon_detail(hackathon_id: UUID):
    return hackathon_service.get_hackathon_detail(str(hackathon_id))
