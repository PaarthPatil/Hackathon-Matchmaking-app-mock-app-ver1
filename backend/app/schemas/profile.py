from __future__ import annotations

from typing import Any, Literal

from pydantic import AliasChoices, BaseModel, ConfigDict, Field, field_validator


ExperienceLevel = Literal["beginner", "intermediate", "advanced"]


class ProfileUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    username: str | None = Field(default=None, max_length=50)
    name: str | None = Field(default=None, max_length=120)
    bio: str | None = Field(default=None, max_length=2000)
    avatar_url: str | None = Field(default=None, max_length=2000)
    skills: list[str] | None = None
    tech_stack: list[str] | None = None
    experience_level: ExperienceLevel | None = None
    github: str | None = Field(default=None, max_length=500)
    linkedin: str | None = Field(default=None, max_length=500)
    portfolio: str | None = Field(default=None, max_length=500)
    looking_for_team: bool | None = None

    # Compatibility fields from Flutter payloads.
    github_link: list[str] | None = None
    linkedin_link: list[str] | None = None
    portfolio_link: list[str] | None = None

    @field_validator(
        "username",
        "name",
        "bio",
        "avatar_url",
        "github",
        "linkedin",
        "portfolio",
        mode="before",
    )
    @classmethod
    def normalize_optional_strings(cls, value: Any) -> Any:
        if value is None:
            return None
        if not isinstance(value, str):
            raise ValueError("Invalid string value.")
        cleaned = value.strip()
        return cleaned or None

    @field_validator("skills", "tech_stack", mode="before")
    @classmethod
    def normalize_string_list(cls, value: Any) -> Any:
        if value is None:
            return None
        if not isinstance(value, list):
            raise ValueError("Expected a list.")
        cleaned = []
        for item in value:
            if not isinstance(item, str):
                continue
            normalized = item.strip()
            if normalized:
                cleaned.append(normalized)
        return cleaned

    @field_validator("experience_level", mode="before")
    @classmethod
    def normalize_experience_level(cls, value: Any) -> Any:
        if value is None:
            return None
        if not isinstance(value, str):
            raise ValueError("Invalid experience level.")
        return value.strip().lower()


class ProfileAvatarUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    avatar_url: str = Field(
        min_length=1,
        max_length=2000,
        validation_alias=AliasChoices("avatar_url", "avatarUrl"),
    )

    @field_validator("avatar_url", mode="before")
    @classmethod
    def validate_avatar_url(cls, value: Any) -> str:
        if not isinstance(value, str):
            raise ValueError("avatar_url is required.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("avatar_url is required.")
        if not (cleaned.startswith("http://") or cleaned.startswith("https://")):
            raise ValueError("avatar_url must be a valid http(s) URL.")
        return cleaned


class ProfileRewardRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    xp: int = Field(gt=0, le=1000)
