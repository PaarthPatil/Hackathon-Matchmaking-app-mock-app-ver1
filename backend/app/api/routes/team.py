from fastapi import APIRouter, Depends

from app.core.dependencies import get_current_user
from app.schemas.team import (
    CreateTeamRequest,
    JoinTeamRequest,
    RecommendationRequest,
    RecommendationResponse,
    TeamMemberActionRequest,
)
from app.services.matching_service import MatchingService
from app.services.team_service import TeamService

router = APIRouter(prefix="/teams", tags=["teams"], dependencies=[Depends(get_current_user)])

team_service = TeamService()
matching_service = MatchingService()


@router.get("/health")
def team_health():
    return {"status": "ok"}


@router.post("/create")
def create_team(payload: CreateTeamRequest, current_user: dict = Depends(get_current_user)):
    return team_service.create_team(user_id=current_user["user_id"], payload=payload)


@router.post("/join")
def join_team(payload: JoinTeamRequest, current_user: dict = Depends(get_current_user)):
    return team_service.join_team(user_id=current_user["user_id"], team_id=str(payload.team_id))


@router.post("/accept")
def accept_team_request(
    payload: TeamMemberActionRequest,
    current_user: dict = Depends(get_current_user),
):
    return team_service.accept_request(
        requester_user_id=current_user["user_id"],
        team_member_id=str(payload.team_member_id),
    )


@router.post("/reject")
def reject_team_request(
    payload: TeamMemberActionRequest,
    current_user: dict = Depends(get_current_user),
):
    return team_service.reject_request(
        requester_user_id=current_user["user_id"],
        team_member_id=str(payload.team_member_id),
    )


@router.post("/recommendations", response_model=list[RecommendationResponse])
def recommend_teams(payload: RecommendationRequest, current_user: dict = Depends(get_current_user)):
    return matching_service.recommend_teams(
        user_id=current_user["user_id"],
        hackathon_id=str(payload.hackathon_id),
    )
