from fastapi import APIRouter, Depends, Query
from uuid import UUID

from app.core.dependencies import get_current_admin
from app.schemas.admin import (
    AdminCreateTeamRequest,
    AdminCreateUserRequest,
    AdminSeedMockDataRequest,
    AdminTriggerEventsRequest,
)
from app.schemas.hackathon import (
    ApproveHackathonRequest,
    CreateHackathonRequest,
    RejectHackathonRequest,
    UpdateHackathonRequest,
)
from app.services.admin_control_service import AdminControlService
from app.services.admin_hackathon_service import AdminHackathonService

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(get_current_admin)])
admin_hackathon_service = AdminHackathonService()
admin_control_service = AdminControlService()


@router.get("/health")
def admin_health():
    return {"status": "ok"}


@router.get("/hackathon-requests")
def list_hackathon_requests(
    status: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    return admin_hackathon_service.list_requests(status_filter=status, limit=limit, offset=offset)


@router.post("/hackathon-requests/{request_id}/approve")
def approve_hackathon_request(request_id: UUID, payload: ApproveHackathonRequest):
    return admin_hackathon_service.approve_request(request_id=str(request_id), payload=payload)


@router.post("/hackathon-requests/{request_id}/reject")
def reject_hackathon_request(request_id: UUID, payload: RejectHackathonRequest):
    return admin_hackathon_service.reject_request(request_id=str(request_id), payload=payload)


@router.post("/hackathons/create")
def create_hackathon(payload: CreateHackathonRequest):
    return admin_hackathon_service.create_hackathon(payload=payload)


@router.put("/hackathons/{hackathon_id}")
def update_hackathon(hackathon_id: UUID, payload: UpdateHackathonRequest):
    return admin_hackathon_service.update_hackathon(hackathon_id=str(hackathon_id), payload=payload)


@router.delete("/hackathons/{hackathon_id}")
def delete_hackathon(hackathon_id: UUID):
    return admin_hackathon_service.delete_hackathon(hackathon_id=str(hackathon_id))


@router.get("/users")
def list_users(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
):
    return admin_control_service.list_users(limit=limit, offset=offset)


@router.post("/users/create")
def create_user(payload: AdminCreateUserRequest):
    return admin_control_service.create_user(payload=payload)


@router.post("/teams/create")
def create_team(payload: AdminCreateTeamRequest):
    return admin_control_service.create_team(payload=payload)


@router.get("/catalog")
def get_admin_catalog():
    return admin_control_service.get_admin_catalog()


@router.post("/testing/seed")
def seed_mock_data(payload: AdminSeedMockDataRequest):
    return admin_control_service.seed_mock_data(payload=payload)


@router.post("/testing/trigger-events")
def trigger_events(payload: AdminTriggerEventsRequest, current_admin: dict = Depends(get_current_admin)):
    return admin_control_service.trigger_test_events(
        admin_user_id=current_admin["user_id"],
        payload=payload,
    )
