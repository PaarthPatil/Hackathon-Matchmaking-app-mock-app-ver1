from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass


@dataclass(frozen=True)
class SmokeEndpoint:
    name: str
    path: str
    auth: str  # public | user | admin


ENDPOINTS: list[SmokeEndpoint] = [
    SmokeEndpoint(name="auth-health", path="/api/v1/auth/health", auth="public"),
    SmokeEndpoint(name="hackathon-health", path="/api/v1/hackathons/health", auth="public"),
    SmokeEndpoint(name="profile-health", path="/api/v1/profile/health", auth="user"),
    SmokeEndpoint(name="teams-health", path="/api/v1/teams/health", auth="user"),
    SmokeEndpoint(name="community-health", path="/api/v1/community/health", auth="user"),
    SmokeEndpoint(name="notifications-health", path="/api/v1/notifications/health", auth="user"),
    SmokeEndpoint(name="chat-health", path="/api/v1/chat/health", auth="user"),
    SmokeEndpoint(name="admin-health", path="/api/v1/admin/health", auth="admin"),
]


def _request(url: str, bearer_token: str | None) -> tuple[int, str]:
    headers = {"Accept": "application/json"}
    if bearer_token:
        headers["Authorization"] = f"Bearer {bearer_token}"
    req = urllib.request.Request(url=url, headers=headers, method="GET")

    try:
        with urllib.request.urlopen(req, timeout=8) as response:
            status = int(getattr(response, "status", 200))
            body = response.read().decode("utf-8", errors="replace")
            return status, body
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        return int(exc.code), body
    except urllib.error.URLError as exc:
        return 0, f"connection_error: {exc.reason}"


def _is_ok_response(status_code: int, body: str) -> bool:
    if status_code != 200:
        return False
    try:
        parsed = json.loads(body)
    except json.JSONDecodeError:
        return False
    return parsed.get("status") == "ok"


def main() -> int:
    parser = argparse.ArgumentParser(description="Catalyst backend smoke check.")
    parser.add_argument(
        "--base-url",
        default=os.getenv("SMOKE_BASE_URL", "http://127.0.0.1:8000"),
        help="Base URL for backend (default: http://127.0.0.1:8000)",
    )
    parser.add_argument(
        "--user-token",
        default=os.getenv("USER_BEARER_TOKEN", ""),
        help="User bearer token for authenticated routes.",
    )
    parser.add_argument(
        "--admin-token",
        default=os.getenv("ADMIN_BEARER_TOKEN", ""),
        help="Admin bearer token for admin routes.",
    )
    parser.add_argument(
        "--strict-auth",
        action="store_true",
        help="Fail if auth tokens are missing for protected checks.",
    )
    args = parser.parse_args()

    user_token = args.user_token.strip() or None
    admin_token = args.admin_token.strip() or None

    passed = 0
    failed = 0
    skipped = 0

    print(f"Running smoke checks against {args.base_url}")
    for endpoint in ENDPOINTS:
        if endpoint.auth == "user" and not user_token:
            skipped += 1
            print(f"[SKIP] {endpoint.name} ({endpoint.path}) requires --user-token")
            continue
        if endpoint.auth == "admin" and not admin_token:
            skipped += 1
            print(f"[SKIP] {endpoint.name} ({endpoint.path}) requires --admin-token")
            continue

        token = None
        if endpoint.auth == "user":
            token = user_token
        elif endpoint.auth == "admin":
            token = admin_token

        status, body = _request(f"{args.base_url}{endpoint.path}", token)
        ok = _is_ok_response(status, body)
        if ok:
            passed += 1
            print(f"[PASS] {endpoint.name} ({endpoint.path})")
        else:
            failed += 1
            print(f"[FAIL] {endpoint.name} ({endpoint.path}) status={status} body={body[:180]}")

    print(
        f"\nSummary: passed={passed} failed={failed} skipped={skipped} total={len(ENDPOINTS)}"
    )

    if args.strict_auth and (user_token is None or admin_token is None):
        print("Strict mode enabled and required auth token is missing.")
        return 1
    if failed > 0:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
