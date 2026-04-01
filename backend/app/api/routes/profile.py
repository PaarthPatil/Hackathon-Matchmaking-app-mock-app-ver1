from fastapi import APIRouter, Depends

from app.core.dependencies import get_current_user
from app.schemas.profile import ProfileAvatarUpdateRequest, ProfileRewardRequest, ProfileUpdateRequest
from app.services.gamification_service import GamificationService
from app.services.profile_service import ProfileService

router = APIRouter(prefix="/profile", tags=["profile"], dependencies=[Depends(get_current_user)])
gamification_service = GamificationService()
profile_service = ProfileService()


@router.get("/health")
def profile_health():
    return {"status": "ok"}


@router.post("/complete")
def mark_profile_completed(current_user: dict = Depends(get_current_user)):
    result = gamification_service.award_profile_completion_xp(user_id=current_user["user_id"])
    return {
        "message": "Profile completion XP processed.",
        "xp": result.get("xp", 0),
        "level": result.get("level", 0),
    }


@router.post("/update")
def update_profile(
    payload: ProfileUpdateRequest,
    current_user: dict = Depends(get_current_user),
):
    return profile_service.update_profile(user_id=current_user["user_id"], payload=payload)


@router.post("/update_avatar")
def update_profile_avatar(
    payload: ProfileAvatarUpdateRequest,
    current_user: dict = Depends(get_current_user),
):
    return profile_service.update_avatar(
        user_id=current_user["user_id"],
        avatar_url=payload.avatar_url,
    )


@router.post("/reward")
def reward_profile_xp(
    payload: ProfileRewardRequest,
    current_user: dict = Depends(get_current_user),
):
    result = gamification_service.award_manual_xp(
        user_id=current_user["user_id"],
        xp_delta=payload.xp,
    )
    return {
        "message": "XP rewarded successfully.",
        "xp": result.get("xp", 0),
        "level": result.get("level", 0),
    }
