from __future__ import annotations

from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.schemas.team import CreateTeamRequest, RecommendationRequest


def test_create_team_requires_non_empty_required_skills():
    with pytest.raises(ValidationError):
        CreateTeamRequest(
            hackathon_id=uuid4(),
            name="Team Alpha",
            description="desc",
            required_skills=[],
            max_members=4,
        )


def test_create_team_accepts_trimmed_skills():
    request = CreateTeamRequest(
        hackathon_id=uuid4(),
        name="Team Alpha",
        description="desc",
        required_skills=[" flutter ", " ", "backend"],
        max_members=4,
    )

    assert request.required_skills == ["flutter", "backend"]


def test_recommendation_force_refresh_default_false():
    request = RecommendationRequest(hackathon_id=uuid4())
    assert request.force_refresh is False
