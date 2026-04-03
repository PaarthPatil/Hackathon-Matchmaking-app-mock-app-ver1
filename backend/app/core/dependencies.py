from typing import Any

from fastapi import Depends, Header, HTTPException, Request, status

from app.core.config import settings
from app.core.security import verify_bearer_authorization
from app.db.supabase_client import supabase


def get_current_user(
    request: Request,
    authorization: str | None = Header(default=None),
) -> dict[str, str]:
    cached = getattr(request.state, "current_user", None)
    if isinstance(cached, dict) and cached.get("user_id"):
        return cached

    current_user = verify_bearer_authorization(authorization)
    request.state.current_user = current_user
    return current_user


def get_current_admin(current_user: dict[str, str] = Depends(get_current_user)) -> dict[str, Any]:
    user_id = current_user["user_id"]

    if user_id in settings.admin_user_ids:
        return {"user_id": user_id, "role": "admin"}

    response = supabase.table("profiles").select("*").eq("id", user_id).limit(1).execute()
    rows = response.data or []

    if not rows:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Profile not found.",
        )

    profile = rows[0]
    role = profile.get("role")
    roles = profile.get("roles") if isinstance(profile.get("roles"), list) else []
    normalized_roles = {
        str(item).strip().lower()
        for item in roles
        if isinstance(item, str) and item.strip()
    }
    if isinstance(role, str) and role.strip():
        normalized_roles.add(role.strip().lower())

    if "admin" not in normalized_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin role required.",
        )

    return {"user_id": user_id, "role": "admin"}
