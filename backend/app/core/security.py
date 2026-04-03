from fastapi import HTTPException, status

from app.db.supabase_client import supabase


def extract_bearer_token(authorization: str | None) -> str | None:
    if not authorization:
        return None

    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        return None
    return token


def verify_supabase_jwt(token: str | None) -> dict[str, str]:
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header missing or invalid.",
        )

    try:
        user_response = supabase.auth.get_user(token)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization token.",
        ) from exc

    user = getattr(user_response, "user", None)
    user_id = getattr(user, "id", None)
    user_email = getattr(user, "email", None)

    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization token.",
        )

    return {"user_id": str(user_id), "email": str(user_email or "")}


def verify_bearer_authorization(authorization: str | None) -> dict[str, str]:
    token = extract_bearer_token(authorization)
    return verify_supabase_jwt(token)
