from __future__ import annotations

import base64
import importlib
import json

from app.core import config as config_module


def _jwt_with_role(role: str) -> str:
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {"role": role}

    def _encode(value: dict) -> str:
        raw = json.dumps(value, separators=(",", ":")).encode("utf-8")
        return base64.urlsafe_b64encode(raw).decode("utf-8").rstrip("=")

    return f"{_encode(header)}.{_encode(payload)}.signature"


def test_has_service_role_key_true(monkeypatch):
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", _jwt_with_role("service_role"))
    importlib.reload(config_module)

    assert config_module.settings.has_service_role_key is True


def test_has_service_role_key_false_for_anon(monkeypatch):
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", _jwt_with_role("anon"))
    importlib.reload(config_module)

    assert config_module.settings.has_service_role_key is False


def test_admin_user_ids_are_parsed(monkeypatch):
    monkeypatch.setenv("ADMIN_USER_IDS", "a, b ,, c")
    importlib.reload(config_module)

    assert config_module.settings.admin_user_ids == {"a", "b", "c"}


def test_has_service_role_key_true_for_secret_key_prefix(monkeypatch):
    monkeypatch.setenv("SUPABASE_SERVICE_ROLE_KEY", "sb_secret_example123")
    importlib.reload(config_module)

    assert config_module.settings.has_service_role_key is True
