from __future__ import annotations

from fastapi import HTTPException, status
from pydantic import ValidationError

from app.core.cache import cache
from app.db.supabase_client import supabase
from app.schemas.hackathon import (
    ApproveHackathonRequest,
    CreateHackathonRequest,
    RejectHackathonRequest,
    UpdateHackathonRequest,
)


class AdminHackathonService:
    def list_requests(self, status_filter: str | None, limit: int, offset: int) -> dict:
        query = (
            supabase.table("hackathon_requests")
            .select("*", count="exact")
            .order("created_at", desc=True)
        )

        if status_filter is not None:
            normalized_status = status_filter.strip().lower()
            if normalized_status not in {"pending", "approved", "rejected"}:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid status filter.",
                )
            query = query.eq("status", normalized_status)

        response = query.range(offset, offset + limit - 1).execute()
        rows = response.data or []
        return {"items": rows, "limit": limit, "offset": offset, "total": int(response.count or 0)}

    def approve_request(self, request_id: str, payload: ApproveHackathonRequest) -> dict:
        request_row = self._get_hackathon_request(request_id)
        if request_row.get("status") != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only pending requests can be approved.",
            )

        merged_hackathon = self._build_hackathon_payload_from_request(request_row, payload)
        self._ensure_hackathon_not_duplicate(merged_hackathon["title"], merged_hackathon["organizer"])

        created_rows = (
            supabase.table("hackathons").insert(merged_hackathon).execute().data or []
        )
        if not created_rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create hackathon from request.",
            )
        created_hackathon = created_rows[0]

        approval_rows = (
            supabase.table("hackathon_requests")
            .update({"status": "approved"})
            .eq("id", request_id)
            .eq("status", "pending")
            .execute()
            .data
            or []
        )
        if not approval_rows:
            # Compensating action: request state changed concurrently, so remove created hackathon.
            supabase.table("hackathons").delete().eq("id", created_hackathon["id"]).execute()
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Hackathon request was already processed.",
            )
        self._notify_request_owner(
            user_id=request_row["user_id"],
            message=f'Your hackathon request "{request_row.get("title", "Untitled")}" has been approved.',
            reference_id=created_hackathon["id"],
        )
        self._invalidate_hackathon_cache(created_hackathon["id"])

        return {
            "message": "Hackathon request approved.",
            "hackathon_id": created_hackathon["id"],
        }

    def reject_request(self, request_id: str, payload: RejectHackathonRequest) -> dict:
        request_row = self._get_hackathon_request(request_id)
        if request_row.get("status") != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only pending requests can be rejected.",
            )

        base_update = {"status": "rejected"}
        if payload.reason:
            try:
                rejected_rows = (
                    supabase.table("hackathon_requests")
                    .update({**base_update, "rejection_reason": payload.reason})
                    .eq("id", request_id)
                    .eq("status", "pending")
                    .execute()
                    .data
                    or []
                )
            except Exception:
                rejected_rows = (
                    supabase.table("hackathon_requests")
                    .update(base_update)
                    .eq("id", request_id)
                    .eq("status", "pending")
                    .execute()
                    .data
                    or []
                )
        else:
            rejected_rows = (
                supabase.table("hackathon_requests")
                .update(base_update)
                .eq("id", request_id)
                .eq("status", "pending")
                .execute()
                .data
                or []
            )
        if not rejected_rows:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Hackathon request was already processed.",
            )

        notify_message = f'Your hackathon request "{request_row.get("title", "Untitled")}" was rejected.'
        if payload.reason:
            notify_message = f"{notify_message} Reason: {payload.reason}"
        self._notify_request_owner(
            user_id=request_row["user_id"],
            message=notify_message,
            reference_id=request_row["id"],
        )

        return {"message": "Hackathon request rejected."}

    def create_hackathon(self, payload: CreateHackathonRequest) -> dict:
        self._ensure_hackathon_not_duplicate(payload.title, payload.organizer)
        insert_payload = payload.model_dump()

        created_rows = (
            supabase.table("hackathons").insert(insert_payload).execute().data or []
        )
        if not created_rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create hackathon.",
            )
        self._invalidate_hackathon_cache(created_rows[0]["id"])
        return {
            "message": "Hackathon created successfully.",
            "hackathon_id": created_rows[0]["id"],
        }

    def update_hackathon(self, hackathon_id: str, payload: UpdateHackathonRequest) -> dict:
        existing = self._get_hackathon(hackathon_id)
        updates = payload.model_dump(exclude_unset=True)
        if not updates:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields provided for update.",
            )

        merged = {
            "title": updates.get("title", existing.get("title")),
            "description": updates.get("description", existing.get("description")),
            "organizer": updates.get("organizer", existing.get("organizer")),
            "start_date": updates.get("start_date", existing.get("start_date")),
            "end_date": updates.get("end_date", existing.get("end_date")),
            "mode": updates.get("mode", existing.get("mode")),
            "location": updates.get("location", existing.get("location")),
            "prize_pool": updates.get("prize_pool", existing.get("prize_pool")),
            "max_team_size": updates.get("max_team_size", existing.get("max_team_size")),
            "tags": updates.get("tags", existing.get("tags", [])),
        }

        # Re-validate full object for required fields and date constraints.
        try:
            validated = CreateHackathonRequest.model_validate(merged)
        except ValidationError as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid update payload: {exc.errors()}",
            ) from exc
        update_payload = validated.model_dump()

        updated_rows = (
            supabase.table("hackathons")
            .update(update_payload)
            .eq("id", hackathon_id)
            .execute()
            .data
            or []
        )
        if not updated_rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update hackathon.",
            )

        self._invalidate_hackathon_cache(hackathon_id)
        return {"message": "Hackathon updated successfully."}

    def delete_hackathon(self, hackathon_id: str) -> dict:
        self._get_hackathon(hackathon_id)

        teams = (
            supabase.table("teams")
            .select("id")
            .eq("hackathon_id", hackathon_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if teams:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Cannot delete hackathon with existing teams.",
            )

        deleted_rows = (
            supabase.table("hackathons").delete().eq("id", hackathon_id).execute().data or []
        )
        if not deleted_rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to delete hackathon.",
            )
        self._invalidate_hackathon_cache(hackathon_id)
        return {"message": "Hackathon deleted successfully."}

    def _build_hackathon_payload_from_request(
        self,
        request_row: dict,
        payload: ApproveHackathonRequest,
    ) -> dict:
        merged = {
            "title": payload.title or request_row.get("title"),
            "description": payload.description or request_row.get("description"),
            "organizer": payload.organizer or request_row.get("organizer"),
            "start_date": payload.start_date or request_row.get("expected_start_date"),
            "end_date": payload.end_date or request_row.get("expected_end_date"),
            "mode": payload.mode or request_row.get("mode"),
            "location": payload.location if payload.location is not None else request_row.get("location"),
            "prize_pool": payload.prize_pool
            if payload.prize_pool is not None
            else request_row.get("prize_pool"),
            "max_team_size": payload.max_team_size or request_row.get("max_team_size"),
            "tags": payload.tags if payload.tags is not None else request_row.get("tags", []),
        }

        try:
            validated = CreateHackathonRequest.model_validate(merged)
        except ValidationError as exc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid approval payload: {exc.errors()}",
            ) from exc
        return validated.model_dump()

    def _ensure_hackathon_not_duplicate(self, title: str, organizer: str) -> None:
        rows = (
            supabase.table("hackathons")
            .select("id, organizer")
            .eq("title", title)
            .execute()
            .data
            or []
        )
        for row in rows:
            if self._normalize_text(row.get("organizer")) == self._normalize_text(organizer):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Duplicate hackathon detected.",
                )

    def _get_hackathon_request(self, request_id: str) -> dict:
        rows = (
            supabase.table("hackathon_requests")
            .select("*")
            .eq("id", request_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Hackathon request not found.",
            )
        return rows[0]

    def _get_hackathon(self, hackathon_id: str) -> dict:
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
        return rows[0]

    def _normalize_text(self, value: str | None) -> str:
        if not value:
            return ""
        return value.strip().lower()

    def _notify_request_owner(self, user_id: str, message: str, reference_id: str) -> None:
        try:
            supabase.table("notifications").insert(
                {
                    "user_id": user_id,
                    "type": "hackathon_request_update",
                    "message": message,
                    "read": False,
                    "reference_id": reference_id,
                }
            ).execute()
        except Exception:
            return

    def _invalidate_hackathon_cache(self, hackathon_id: str) -> None:
        cache.invalidate_prefix("hackathons:list:")
        cache.invalidate_prefix(f"hackathons:detail:{hackathon_id}")
