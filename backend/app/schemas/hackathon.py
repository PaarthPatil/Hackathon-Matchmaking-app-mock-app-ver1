from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


HackathonMode = Literal["online", "offline", "hybrid"]


class HackathonRequestCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")
    title: str = Field(min_length=1, max_length=200)
    description: str = Field(min_length=1, max_length=4000)
    organizer: str | None = Field(default=None, max_length=200)
    expected_start_date: datetime
    expected_end_date: datetime
    mode: HackathonMode
    location: str | None = Field(default=None, max_length=300)
    tags: list[str] = Field(default_factory=list)
    additional_metadata: dict[str, Any] = Field(default_factory=dict)

    @field_validator("title", "description", "organizer", "location", mode="before")
    @classmethod
    def strip_strings(cls, value: Any) -> Any:
        if isinstance(value, str):
            cleaned = value.strip()
            return cleaned or None
        return value

    @field_validator("title", "description")
    @classmethod
    def ensure_required_not_empty(cls, value: str | None) -> str:
        if not value:
            raise ValueError("Field must not be empty.")
        return value

    @field_validator("tags")
    @classmethod
    def normalize_tags(cls, value: list[Any]) -> list[str]:
        normalized = []
        for tag in value:
            if not isinstance(tag, str):
                continue
            cleaned = tag.strip()
            if cleaned:
                normalized.append(cleaned)
        return normalized

    @field_validator("mode", mode="before")
    @classmethod
    def normalize_mode(cls, value: Any) -> Any:
        if isinstance(value, str):
            return value.strip().lower()
        return value

    @model_validator(mode="after")
    def validate_dates_and_location(self) -> "HackathonRequestCreate":
        if self.expected_end_date <= self.expected_start_date:
            raise ValueError("expected_end_date must be later than expected_start_date.")
        if self.mode in {"offline", "hybrid"} and not self.location:
            raise ValueError("location is required for offline or hybrid mode.")
        return self


class CreateHackathonRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    title: str = Field(min_length=1, max_length=200)
    description: str = Field(min_length=1, max_length=4000)
    organizer: str = Field(min_length=1, max_length=200)
    start_date: datetime
    end_date: datetime
    mode: HackathonMode
    location: str | None = Field(default=None, max_length=300)
    prize_pool: str | None = Field(default=None, max_length=200)
    max_team_size: int = Field(ge=1, le=20)
    tags: list[str] = Field(default_factory=list)

    @field_validator("title", "description", "organizer", "location", "prize_pool", mode="before")
    @classmethod
    def strip_strings(cls, value: Any) -> Any:
        if isinstance(value, str):
            cleaned = value.strip()
            return cleaned or None
        return value

    @field_validator("title", "description", "organizer")
    @classmethod
    def ensure_required_not_empty(cls, value: str | None) -> str:
        if not value:
            raise ValueError("Field must not be empty.")
        return value

    @field_validator("tags")
    @classmethod
    def normalize_tags(cls, value: list[Any]) -> list[str]:
        normalized = []
        for tag in value:
            if not isinstance(tag, str):
                continue
            cleaned = tag.strip()
            if cleaned:
                normalized.append(cleaned)
        return normalized

    @field_validator("mode", mode="before")
    @classmethod
    def normalize_mode(cls, value: Any) -> Any:
        if isinstance(value, str):
            return value.strip().lower()
        return value

    @model_validator(mode="after")
    def validate_dates_and_location(self) -> "CreateHackathonRequest":
        if self.end_date <= self.start_date:
            raise ValueError("end_date must be later than start_date.")
        if self.mode in {"offline", "hybrid"} and not self.location:
            raise ValueError("location is required for offline or hybrid mode.")
        return self


class UpdateHackathonRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, min_length=1, max_length=4000)
    organizer: str | None = Field(default=None, min_length=1, max_length=200)
    start_date: datetime | None = None
    end_date: datetime | None = None
    mode: HackathonMode | None = None
    location: str | None = Field(default=None, max_length=300)
    prize_pool: str | None = Field(default=None, max_length=200)
    max_team_size: int | None = Field(default=None, ge=1, le=20)
    tags: list[str] | None = None

    @field_validator("title", "description", "organizer", "location", "prize_pool", mode="before")
    @classmethod
    def strip_strings(cls, value: Any) -> Any:
        if isinstance(value, str):
            cleaned = value.strip()
            return cleaned or None
        return value

    @field_validator("tags")
    @classmethod
    def normalize_tags(cls, value: list[Any] | None) -> list[str] | None:
        if value is None:
            return None
        normalized = []
        for tag in value:
            if not isinstance(tag, str):
                continue
            cleaned = tag.strip()
            if cleaned:
                normalized.append(cleaned)
        return normalized

    @field_validator("mode", mode="before")
    @classmethod
    def normalize_mode(cls, value: Any) -> Any:
        if isinstance(value, str):
            return value.strip().lower()
        return value


class ApproveHackathonRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, min_length=1, max_length=4000)
    organizer: str | None = Field(default=None, min_length=1, max_length=200)
    start_date: datetime | None = None
    end_date: datetime | None = None
    mode: HackathonMode | None = None
    location: str | None = Field(default=None, max_length=300)
    prize_pool: str | None = Field(default=None, max_length=200)
    max_team_size: int | None = Field(default=None, ge=1, le=20)
    tags: list[str] | None = None

    @field_validator("title", "description", "organizer", "location", "prize_pool", mode="before")
    @classmethod
    def strip_strings(cls, value: Any) -> Any:
        if isinstance(value, str):
            cleaned = value.strip()
            return cleaned or None
        return value

    @field_validator("tags")
    @classmethod
    def normalize_tags(cls, value: list[Any] | None) -> list[str] | None:
        if value is None:
            return None
        normalized = []
        for tag in value:
            if not isinstance(tag, str):
                continue
            cleaned = tag.strip()
            if cleaned:
                normalized.append(cleaned)
        return normalized

    @field_validator("mode", mode="before")
    @classmethod
    def normalize_mode(cls, value: Any) -> Any:
        if isinstance(value, str):
            return value.strip().lower()
        return value


class RejectHackathonRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    reason: str | None = Field(default=None, max_length=1000)

    @field_validator("reason", mode="before")
    @classmethod
    def strip_reason(cls, value: Any) -> Any:
        if isinstance(value, str):
            cleaned = value.strip()
            return cleaned or None
        return value


class HackathonListItem(BaseModel):
    id: str
    title: str
    description: str
    organizer: str
    start_date: datetime
    end_date: datetime
    mode: HackathonMode
    location: str | None = None
    prize_pool: str | None = None
    max_team_size: int
    tags: list[str] = Field(default_factory=list)
    created_at: datetime | None = None


class HackathonListResponse(BaseModel):
    items: list[HackathonListItem]
    page: int
    page_size: int
    total: int
