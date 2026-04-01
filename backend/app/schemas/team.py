from uuid import UUID

from pydantic import BaseModel, Field, field_validator


class CreateTeamRequest(BaseModel):
    hackathon_id: UUID
    name: str = Field(min_length=1, max_length=120)
    description: str = Field(default="", max_length=2000)
    required_skills: list[str] = Field(default_factory=list)
    max_members: int = Field(ge=1, le=20)

    @field_validator("required_skills")
    @classmethod
    def validate_required_skills(cls, value: list[str]) -> list[str]:
        cleaned = [skill.strip() for skill in value if skill and skill.strip()]
        if not cleaned:
            raise ValueError("required_skills must not be empty.")
        return cleaned


class JoinTeamRequest(BaseModel):
    team_id: UUID


class RecommendationRequest(BaseModel):
    hackathon_id: UUID


class TeamMemberActionRequest(BaseModel):
    team_member_id: UUID


class RecommendationResponse(BaseModel):
    team_id: str
    team_name: str
    members_count: int
    compatibility_score: float
    explanation: str
