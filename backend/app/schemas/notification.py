from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


class NotificationReadRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: UUID


class NotificationDeleteRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: UUID


class NotificationCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    type: str = Field(min_length=1, max_length=120)
    message: str = Field(min_length=1, max_length=1000)
    reference_id: UUID | None = None

    @field_validator("type", "message", mode="before")
    @classmethod
    def strip_required_strings(cls, value: Any) -> str:
        if not isinstance(value, str):
            raise ValueError("Invalid value.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Value must not be empty.")
        return cleaned


class NotificationCreateInternal(BaseModel):
    user_id: str
    type: str
    message: str
    reference_id: str | None = None
    read: bool = False

    @field_validator("type", "message", mode="before")
    @classmethod
    def strip_required_strings(cls, value: Any) -> str:
        if not isinstance(value, str):
            raise ValueError("Invalid value.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Value must not be empty.")
        return cleaned


class NotificationResponse(BaseModel):
    id: str
    user_id: str
    type: str
    message: str
    read: bool
    reference_id: str | None = None
    created_at: datetime
