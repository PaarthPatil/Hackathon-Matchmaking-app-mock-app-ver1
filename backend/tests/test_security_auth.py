from __future__ import annotations

from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.core.security import verify_bearer_authorization, verify_supabase_jwt


def test_verify_supabase_jwt_requires_token():
    with pytest.raises(HTTPException) as exc:
        verify_supabase_jwt(None)
    assert exc.value.status_code == 401


def test_verify_bearer_authorization_rejects_invalid_header():
    with pytest.raises(HTTPException) as exc:
        verify_bearer_authorization("Basic abc")
    assert exc.value.status_code == 401


def test_verify_supabase_jwt_returns_user_and_email(monkeypatch):
    fake_user = SimpleNamespace(id="user-123", email="user@example.com")
    fake_response = SimpleNamespace(user=fake_user)

    from app.core import security as security_module

    monkeypatch.setattr(
        security_module.supabase.auth,
        "get_user",
        lambda _token: fake_response,
    )

    result = verify_supabase_jwt("valid-token")
    assert result["user_id"] == "user-123"
    assert result["email"] == "user@example.com"
