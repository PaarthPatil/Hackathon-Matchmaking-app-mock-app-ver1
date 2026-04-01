from fastapi import APIRouter, Depends, Query
from uuid import UUID

from app.core.dependencies import get_current_user
from app.schemas.community import (
    CommentListResponse,
    CommunityFeedResponse,
    CreateCommentRequest,
    CreatePostRequest,
    VotePostRequest,
)
from app.services.community_service import CommunityService

router = APIRouter(prefix="/community", tags=["community"], dependencies=[Depends(get_current_user)])
community_service = CommunityService()


@router.get("/health")
def community_health():
    return {"status": "ok"}


@router.post("/posts")
def create_post(payload: CreatePostRequest, current_user: dict = Depends(get_current_user)):
    return community_service.create_post(user_id=current_user["user_id"], payload=payload)


@router.get("/posts", response_model=CommunityFeedResponse)
def get_posts(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    sort: str = Query(default="latest"),
):
    return community_service.get_posts(limit=limit, offset=offset, sort=sort)


@router.post("/vote")
def vote(payload: VotePostRequest, current_user: dict = Depends(get_current_user)):
    return community_service.vote_post(
        user_id=current_user["user_id"],
        post_id=str(payload.post_id),
        vote_type=payload.normalized_vote_type,
    )


@router.post("/comments")
def create_comment(payload: CreateCommentRequest, current_user: dict = Depends(get_current_user)):
    return community_service.create_comment(user_id=current_user["user_id"], payload=payload)


@router.get("/comments/{post_id}", response_model=CommentListResponse)
def get_comments(
    post_id: UUID,
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    return community_service.get_comments(post_id=str(post_id), limit=limit, offset=offset)


@router.get("/comments", response_model=CommentListResponse)
def get_comments_by_query(
    post_id: UUID = Query(...),
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    return community_service.get_comments(post_id=str(post_id), limit=limit, offset=offset)
