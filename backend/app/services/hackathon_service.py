from __future__ import annotations

import logging

from fastapi import HTTPException, status
from pydantic import ValidationError

from app.core.cache import cache
from app.db.supabase_client import supabase
from app.schemas.hackathon import (
    HackathonListItem,
    HackathonListResponse,
    HackathonRequestCreate,
)

logger = logging.getLogger(__name__)


class HackathonService:
    def submit_request(self, user_id: str, payload: HackathonRequestCreate) -> dict:
        duplicate_requests = (
            supabase.table("hackathon_requests")
            .select("id, status, organizer")
            .eq("title", payload.title)
            .execute()
            .data
            or []
        )

        has_pending_duplicate = any(
            self._normalize_text(row.get("organizer")) == self._normalize_text(payload.organizer)
            and row.get("status") == "pending"
            for row in duplicate_requests
        )
        if has_pending_duplicate:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="A similar hackathon request is already pending review.",
            )

        insert_payload = {
            "user_id": user_id,
            "title": payload.title,
            "description": payload.description,
            "organizer": payload.organizer,
            "expected_start_date": payload.expected_start_date.isoformat(),
            "expected_end_date": payload.expected_end_date.isoformat(),
            "mode": payload.mode,
            "location": payload.location,
            "tags": payload.tags,
            "additional_metadata": payload.additional_metadata,
            "status": "pending",
        }

        inserted_rows = (
            supabase.table("hackathon_requests").insert(insert_payload).execute().data or []
        )
        if not inserted_rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to submit hackathon request.",
            )

        return {
            "request_id": inserted_rows[0]["id"],
            "status": inserted_rows[0].get("status", "pending"),
            "message": "Hackathon request submitted for admin review.",
        }

    def list_hackathons(self, page: int, page_size: int) -> HackathonListResponse:
        cache_key = f"hackathons:list:{page}:{page_size}"
        cached = cache.get(cache_key)
        if isinstance(cached, dict):
            return HackathonListResponse.model_validate(cached)

        start = (page - 1) * page_size
        end = start + page_size

        query = (
            supabase.table("hackathons")
            .select("*", count="exact")
            .order("start_date", desc=False)
            .range(start, end - 1)
        )
        response = query.execute()
        rows = response.data or []
        total = int(response.count or 0)
        logger.info(
            "Hackathons fetched | page=%s page_size=%s rows=%s total=%s",
            page,
            page_size,
            len(rows),
            total,
        )

        try:
            items = [HackathonListItem.model_validate(row) for row in rows]
        except ValidationError as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Hackathon data is invalid in database.",
            ) from exc
        result = HackathonListResponse(items=items, page=page, page_size=page_size, total=total)
        cache.set(cache_key, result.model_dump(mode="json"), ttl_seconds=60)
        return result

    def get_hackathon_detail(self, hackathon_id: str) -> HackathonListItem:
        cache_key = f"hackathons:detail:{hackathon_id}"
        cached = cache.get(cache_key)
        if isinstance(cached, dict):
            return HackathonListItem.model_validate(cached)

        rows = (
            supabase.table("hackathons")
            .select("*")
            .eq("id", hackathon_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Hackathon not found",
            )
        logger.info("Hackathon detail fetched | hackathon_id=%s", hackathon_id)

        try:
            result = HackathonListItem.model_validate(rows[0])
        except ValidationError as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Hackathon data is invalid in database.",
            ) from exc
        cache.set(cache_key, result.model_dump(mode="json"), ttl_seconds=60)
        return result

    def _normalize_text(self, value: str | None) -> str:
        if not value:
            return ""
        return value.strip().lower()
