from pydantic import ValidationError

from app.schemas.chat import SendMessageRequest
from app.schemas.profile import (
    ProfileAvatarUpdateRequest,
    ProfileRewardRequest,
    ProfileUpdateRequest,
)


def test_profile_update_normalizes_experience_level() -> None:
    payload = ProfileUpdateRequest(experience_level="Beginner")
    assert payload.experience_level == "beginner"


def test_profile_avatar_accepts_camel_case_input() -> None:
    payload = ProfileAvatarUpdateRequest.model_validate(
        {"avatarUrl": "https://example.com/avatar.png"}
    )
    assert payload.avatar_url == "https://example.com/avatar.png"


def test_profile_reward_requires_positive_xp() -> None:
    try:
        ProfileRewardRequest(xp=0)
        assert False, "Expected validation error for non-positive xp."
    except ValidationError:
        assert True


def test_chat_message_rejects_blank_content() -> None:
    try:
        SendMessageRequest(
            team_id="00000000-0000-0000-0000-000000000000",
            content="   ",
        )
        assert False, "Expected validation error for blank content."
    except ValidationError:
        assert True
