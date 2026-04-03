from __future__ import annotations

from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import BaseModel, Field, field_validator, model_validator


class CreatePostRequest(BaseModel):
    content: str = Field(min_length=1, max_length=5000)
    image_url: str | None = Field(default=None, max_length=2000)

    @field_validator("content", mode="before")
    @classmethod
    def validate_content(cls, value: Any) -> str:
        if not isinstance(value, str):
            raise ValueError("content is required.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("content must not be empty.")
        return cleaned

    @field_validator("image_url", mode="before")
    @classmethod
    def validate_image_url(cls, value: Any) -> str | None:
        if value is None:
            return None
        if not isinstance(value, str):
            raise ValueError("image_url must be a string.")
        cleaned = value.strip()
        if not cleaned:
            return None
        if not (cleaned.startswith("http://") or cleaned.startswith("https://")):
            raise ValueError("image_url must be a valid http(s) URL.")
        return cleaned


class VotePostRequest(BaseModel):
    post_id: UUID
    vote_type: Literal["upvote", "downvote"] | None = None
    direction: Literal["up", "down"] | None = None

    @model_validator(mode="after")
    def validate_vote_source(self) -> "VotePostRequest":
        if self.vote_type is None and self.direction is None:
            raise ValueError("vote_type or direction is required.")
        return self

    @property
    def normalized_vote_type(self) -> str:
        if self.vote_type is not None:
            return self.vote_type
        if self.direction == "up":
            return "upvote"
        return "downvote"


class CreateCommentRequest(BaseModel):
    post_id: UUID
    content: str = Field(min_length=1, max_length=2000)

    @field_validator("content", mode="before")
    @classmethod
    def validate_content(cls, value: Any) -> str:
        if not isinstance(value, str):
            raise ValueError("content is required.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("content must not be empty.")
        return cleaned


class UpdatePostRequest(BaseModel):
    content: str | None = Field(default=None, min_length=1, max_length=5000)
    image_url: str | None = Field(default=None, max_length=2000)

    @field_validator("content", mode="before")
    @classmethod
    def validate_content(cls, value: Any) -> str | None:
        if value is None:
            return None
        if not isinstance(value, str):
            raise ValueError("content must be a string.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("content must not be empty.")
        return cleaned

    @field_validator("image_url", mode="before")
    @classmethod
    def validate_image_url(cls, value: Any) -> str | None:
        if value is None:
            return None
        if not isinstance(value, str):
            raise ValueError("image_url must be a string.")
        cleaned = value.strip()
        if not cleaned:
            return None
        if not (cleaned.startswith("http://") or cleaned.startswith("https://")):
            raise ValueError("image_url must be a valid http(s) URL.")
        return cleaned


class UpdateCommentRequest(BaseModel):
    content: str = Field(min_length=1, max_length=2000)

    @field_validator("content", mode="before")
    @classmethod
    def validate_content(cls, value: Any) -> str:
        if not isinstance(value, str):
            raise ValueError("content is required.")
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("content must not be empty.")
        return cleaned


class CommunityFeedItem(BaseModel):
    id: str
    user_id: str
    content: str
    image_url: str | None = None
    upvotes: int
    downvotes: int
    created_at: datetime
    profiles: dict[str, Any] | None = None


class CommunityFeedResponse(BaseModel):
    items: list[CommunityFeedItem]
    limit: int
    offset: int
    sort: str
    total: int


class CommentResponse(BaseModel):
    id: str
    post_id: str
    user_id: str
    content: str
    created_at: datetime
    profiles: dict[str, Any] | None = None


class CommentListResponse(BaseModel):
    items: list[CommentResponse]
    limit: int
    offset: int
    total: int
