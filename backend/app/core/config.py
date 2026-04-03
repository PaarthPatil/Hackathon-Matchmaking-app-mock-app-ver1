import os
import json
import base64
from dataclasses import dataclass

from dotenv import load_dotenv


load_dotenv()


@dataclass(frozen=True)
class Settings:
    supabase_url: str = os.getenv("SUPABASE_URL", "")
    supabase_key: str = os.getenv("SUPABASE_KEY", "")
    supabase_service_role_key: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
    jwt_secret: str = os.getenv("JWT_SECRET", "")
    log_level: str = os.getenv("LOG_LEVEL", "INFO")
    environment: str = os.getenv("ENVIRONMENT", "development")
    cors_origins_raw: str = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://localhost:5173")
    post_create_limit_per_minute: int = int(os.getenv("POST_CREATE_LIMIT_PER_MINUTE", "5"))
    vote_limit_per_minute: int = int(os.getenv("VOTE_LIMIT_PER_MINUTE", "30"))
    team_join_limit_per_10min: int = int(os.getenv("TEAM_JOIN_LIMIT_PER_10MIN", "10"))
    redis_url: str = os.getenv("REDIS_URL", "")
    admin_user_ids_raw: str = os.getenv(
        "ADMIN_USER_IDS",
        "00000000-0000-0000-0000-000000000000,00000000-0000-0000-0000-111111111111",
    )

    @property
    def cors_origins(self) -> list[str]:
        items = [origin.strip() for origin in self.cors_origins_raw.split(",")]
        cleaned = [origin for origin in items if origin]
        if self.environment.lower() == "production":
            return cleaned
        return cleaned or ["*"]

    @property
    def admin_user_ids(self) -> set[str]:
        return {
            item.strip()
            for item in self.admin_user_ids_raw.split(",")
            if item and item.strip()
        }

    @property
    def has_service_role_key(self) -> bool:
        token = (self.supabase_service_role_key or "").strip()
        if not token:
            return False
        if token.startswith("sb_secret_"):
            return True
        parts = token.split(".")
        if len(parts) != 3:
            return False
        payload_part = parts[1]
        padding = "=" * (-len(payload_part) % 4)
        try:
            decoded = base64.urlsafe_b64decode(payload_part + padding)
            payload = json.loads(decoded.decode("utf-8"))
        except Exception:
            return False
        return str(payload.get("role", "")).strip().lower() == "service_role"


settings = Settings()
