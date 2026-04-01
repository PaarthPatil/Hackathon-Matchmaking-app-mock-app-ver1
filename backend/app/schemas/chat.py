from __future__ import annotations

from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


class SendMessageRequest(BaseModel):
    model_config = ConfigDict(extra="ignore")

    team_id: UUID
    content: str = Field(min_length=1, max_length=4000)

    @field_validator("content", mode="before")
    @classmethod
    def validate_content(cls, value: Any) -> str:
        if not isinstance(value, str):
            raise ValueError("content is required.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("content is required.")
        return cleaned
