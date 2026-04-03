from __future__ import annotations

from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


class AdminCreateUserRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    email: str = Field(min_length=5, max_length=320)
    password: str = Field(min_length=8, max_length=200)
    username: str = Field(min_length=3, max_length=50)
    name: str = Field(min_length=1, max_length=120)
    bio: str | None = Field(default=None, max_length=2000)
    role: Literal["admin", "user"] = "user"
    skills: list[str] = Field(default_factory=list)
    tech_stack: list[str] = Field(default_factory=list)
    experience_level: Literal["beginner", "intermediate", "advanced"] = "intermediate"
    looking_for_team: bool = True

    @field_validator("email", "username", "name", "bio", mode="before")
    @classmethod
    def strip_strings(cls, value: Any) -> Any:
        if not isinstance(value, str):
            return value
        cleaned = value.strip()
        return cleaned or None

    @field_validator("email")
    @classmethod
    def normalize_email(cls, value: str) -> str:
        return value.lower()

    @field_validator("skills", "tech_stack", mode="before")
    @classmethod
    def normalize_string_lists(cls, value: Any) -> Any:
        if value is None:
            return []
        if not isinstance(value, list):
            raise ValueError("Expected a list.")
        cleaned: list[str] = []
        for item in value:
            if not isinstance(item, str):
                continue
            normalized = item.strip()
            if normalized:
                cleaned.append(normalized)
        return cleaned


class AdminCreateTeamRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    hackathon_id: UUID
    creator_user_id: UUID
    name: str = Field(min_length=1, max_length=120)
    description: str = Field(default="", max_length=2000)
    required_skills: list[str] = Field(default_factory=list)
    max_members: int = Field(default=4, ge=1, le=20)
    commitment_level: str | None = Field(default=None, max_length=100)
    availability: str | None = Field(default=None, max_length=200)

    @field_validator("name", "description", "commitment_level", "availability", mode="before")
    @classmethod
    def strip_optional_strings(cls, value: Any) -> Any:
        if isinstance(value, str):
            cleaned = value.strip()
            return cleaned
        return value

    @field_validator("required_skills", mode="before")
    @classmethod
    def normalize_required_skills(cls, value: Any) -> Any:
        if value is None:
            return []
        if not isinstance(value, list):
            raise ValueError("required_skills must be a list.")
        cleaned: list[str] = []
        for skill in value:
            if not isinstance(skill, str):
                continue
            normalized = skill.strip()
            if normalized:
                cleaned.append(normalized)
        return cleaned


class AdminSeedMockDataRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    user_count: int = Field(default=8, ge=1, le=100)
    hackathon_count: int = Field(default=3, ge=1, le=20)
    teams_per_hackathon: int = Field(default=2, ge=1, le=10)
    include_social_feed: bool = True


class AdminTriggerEventsRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    target_user_id: UUID | None = None
    target_team_id: UUID | None = None
    target_post_id: UUID | None = None
    create_notification: bool = True
    create_post: bool = True
    create_comment: bool = True
    create_join_request: bool = True
    create_chat_message: bool = True
    message: str | None = Field(default=None, max_length=500)

    @field_validator("message", mode="before")
    @classmethod
    def normalize_message(cls, value: Any) -> Any:
        if value is None:
            return None
        if not isinstance(value, str):
            return value
        cleaned = value.strip()
        return cleaned or None


class AdminActivityItem(BaseModel):
    event: str
    status: Literal["success", "skipped", "failed"]
    details: str
    reference_id: str | None = None
    occurred_at: datetime = Field(default_factory=datetime.utcnow)
