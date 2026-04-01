from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status

from app.core.config import settings
from app.core.rate_limiter import rate_limiter
from app.db.supabase_client import supabase
from app.schemas.community import (
    CommentListResponse,
    CommentResponse,
    CommunityFeedItem,
    CommunityFeedResponse,
    CreateCommentRequest,
    CreatePostRequest,
)
from app.schemas.notification import NotificationCreateInternal
from app.services.gamification_service import GamificationService
from app.services.notification_service import NotificationService


class CommunityService:
    def __init__(self) -> None:
        self._gamification = GamificationService()
        self._notifications = NotificationService()

    def create_post(self, user_id: str, payload: CreatePostRequest) -> dict:
        rate_limiter.check(
            user_id=user_id,
            action="community_post_create",
            limit=settings.post_create_limit_per_minute,
            window_seconds=60,
        )
        insert_payload = {
            "user_id": user_id,
            "content": payload.content,
            "image_url": payload.image_url,
            "upvotes": 0,
            "downvotes": 0,
        }
        rows = supabase.table("posts").insert(insert_payload).execute().data or []
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create post.",
            )
        post = rows[0]
        self._gamification.award_post_creation_xp(user_id=user_id, post_id=post["id"])
        return {"post_id": post["id"], "message": "Post created successfully."}

    def get_posts(
        self,
        limit: int,
        offset: int,
        sort: str,
    ) -> CommunityFeedResponse:
        normalized_sort = sort.strip().lower()
        if normalized_sort not in {"latest", "trending"}:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid sort. Use latest or trending.",
            )

        if normalized_sort == "latest":
            response = (
                supabase.table("posts")
                .select(
                    "id,user_id,content,image_url,upvotes,downvotes,created_at,profiles:user_id(id,username,name,avatar_url)",
                    count="exact",
                )
                .order("created_at", desc=True)
                .range(offset, offset + limit - 1)
                .execute()
            )
            rows = response.data or []
            items = [CommunityFeedItem.model_validate(row) for row in rows]
            return CommunityFeedResponse(
                items=items,
                limit=limit,
                offset=offset,
                sort=normalized_sort,
                total=int(response.count or 0),
            )

        # Trending feed: score = (upvotes - downvotes) + recency boost
        count_response = supabase.table("posts").select("id", count="exact").execute()
        total_posts = int(count_response.count or 0)
        if total_posts == 0:
            return CommunityFeedResponse(
                items=[],
                limit=limit,
                offset=offset,
                sort=normalized_sort,
                total=0,
            )

        pool_size = min(max(offset + (limit * 10), 500), 5000)
        trending_pool = (
            supabase.table("posts")
            .select("id,user_id,content,image_url,upvotes,downvotes,created_at,profiles:user_id(id,username,name,avatar_url)")
            .order("created_at", desc=True)
            .range(0, pool_size - 1)
            .execute()
            .data
            or []
        )
        scored = sorted(
            trending_pool,
            key=self._trending_score,
            reverse=True,
        )
        paged = scored[offset : offset + limit]
        items = [CommunityFeedItem.model_validate(row) for row in paged]
        return CommunityFeedResponse(
            items=items,
            limit=limit,
            offset=offset,
            sort=normalized_sort,
            total=total_posts,
        )

    def vote_post(self, user_id: str, post_id: str, vote_type: str) -> dict:
        rate_limiter.check(
            user_id=user_id,
            action="community_vote",
            limit=settings.vote_limit_per_minute,
            window_seconds=60,
        )
        post = self._get_post(post_id)

        existing_rows = (
            supabase.table("post_votes")
            .select("vote_type")
            .eq("post_id", post_id)
            .eq("user_id", user_id)
            .limit(1)
            .execute()
            .data
            or []
        )

        created_or_changed_to_upvote = False

        if not existing_rows:
            try:
                supabase.table("post_votes").insert(
                    {
                        "post_id": post_id,
                        "user_id": user_id,
                        "vote_type": vote_type,
                    }
                ).execute()
            except Exception as exc:
                message = str(exc).lower()
                if "duplicate" in message or "unique" in message:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Vote already recorded.",
                    ) from exc
                raise
            if vote_type == "upvote":
                created_or_changed_to_upvote = True
        else:
            current_vote = existing_rows[0].get("vote_type")
            if current_vote == vote_type:
                return {"message": "Vote already recorded."}
            supabase.table("post_votes").update({"vote_type": vote_type}).eq("post_id", post_id).eq(
                "user_id", user_id
            ).execute()
            if vote_type == "upvote":
                created_or_changed_to_upvote = True

        counters = self._sync_post_vote_counters(post_id)

        if created_or_changed_to_upvote and post.get("user_id") != user_id:
            self._notifications.create_notification_safely(
                NotificationCreateInternal(
                    user_id=post["user_id"],
                    type="post_liked",
                    message="Someone liked your post.",
                    reference_id=post_id,
                )
            )

        return {
            "message": "Vote processed.",
            "upvotes": counters["upvotes"],
            "downvotes": counters["downvotes"],
        }

    def create_comment(self, user_id: str, payload: CreateCommentRequest) -> dict:
        post_id = str(payload.post_id)
        post = self._get_post(post_id)
        rows = (
            supabase.table("comments")
            .insert(
                {
                    "post_id": post_id,
                    "user_id": user_id,
                    "content": payload.content,
                }
            )
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create comment.",
            )

        if post.get("user_id") != user_id:
            self._notifications.create_notification_safely(
                NotificationCreateInternal(
                    user_id=post["user_id"],
                    type="post_commented",
                    message="Someone commented on your post.",
                    reference_id=post_id,
                )
            )

        return {"comment_id": rows[0]["id"], "message": "Comment created successfully."}

    def get_comments(self, post_id: str, limit: int, offset: int) -> CommentListResponse:
        self._get_post(post_id)
        rows = (
            supabase.table("comments")
            .select("id,post_id,user_id,content,created_at,profiles:user_id(id,username,name,avatar_url)")
            .eq("post_id", post_id)
            .order("created_at", desc=False)
            .range(offset, offset + limit - 1)
            .execute()
        )
        data_rows = rows.data or []
        count_response = (
            supabase.table("comments")
            .select("id", count="exact")
            .eq("post_id", post_id)
            .execute()
        )
        items = [CommentResponse.model_validate(row) for row in data_rows]
        return CommentListResponse(
            items=items,
            limit=limit,
            offset=offset,
            total=int(count_response.count or 0),
        )

    def _get_post(self, post_id: str) -> dict:
        rows = (
            supabase.table("posts")
            .select("id,user_id")
            .eq("id", post_id)
            .limit(1)
            .execute()
            .data
            or []
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found.",
            )
        return rows[0]

    def _sync_post_vote_counters(self, post_id: str) -> dict[str, int]:
        upvote_count_response = (
            supabase.table("post_votes")
            .select("id", count="exact")
            .eq("post_id", post_id)
            .eq("vote_type", "upvote")
            .execute()
        )
        downvote_count_response = (
            supabase.table("post_votes")
            .select("id", count="exact")
            .eq("post_id", post_id)
            .eq("vote_type", "downvote")
            .execute()
        )
        upvotes = int(upvote_count_response.count or 0)
        downvotes = int(downvote_count_response.count or 0)
        supabase.table("posts").update({"upvotes": upvotes, "downvotes": downvotes}).eq(
            "id", post_id
        ).execute()
        return {"upvotes": upvotes, "downvotes": downvotes}

    def _trending_score(self, row: dict) -> float:
        upvotes = float(row.get("upvotes") or 0)
        downvotes = float(row.get("downvotes") or 0)
        base_score = upvotes - downvotes
        created_at_raw = row.get("created_at")
        if not isinstance(created_at_raw, str):
            return base_score
        try:
            created_at = datetime.fromisoformat(created_at_raw.replace("Z", "+00:00"))
        except ValueError:
            return base_score
        hours_old = max(
            0.0,
            (datetime.now(timezone.utc) - created_at.astimezone(timezone.utc)).total_seconds() / 3600.0,
        )
        recency_boost = max(0.0, (72.0 - hours_old) / 72.0)
        return base_score + recency_boost
