from __future__ import annotations

import json
import logging
import threading
import time
from typing import Any

from app.core.config import settings

logger = logging.getLogger(__name__)


try:
    from redis import Redis
except Exception:  # pragma: no cover - optional dependency fallback
    Redis = None  # type: ignore[assignment]


class TTLCache:
    def __init__(self) -> None:
        self._values: dict[str, tuple[float, Any]] = {}
        self._lock = threading.Lock()
        self._redis = self._create_redis_client()

    def _create_redis_client(self) -> Redis | None:
        if not settings.redis_url or Redis is None:
            return None
        try:
            return Redis.from_url(settings.redis_url, decode_responses=True)
        except Exception:
            logger.exception("Failed to initialize Redis cache client; falling back to in-memory cache.")
            return None

    def get(self, key: str) -> Any | None:
        if self._redis is not None:
            try:
                raw = self._redis.get(key)
                if raw is None:
                    return None
                return json.loads(raw)
            except Exception:
                logger.exception("Redis cache get failed for key=%s; falling back to in-memory.", key)

        now = time.monotonic()
        with self._lock:
            item = self._values.get(key)
            if not item:
                return None
            expires_at, value = item
            if expires_at <= now:
                self._values.pop(key, None)
                return None
            return value

    def set(self, key: str, value: Any, ttl_seconds: int) -> None:
        if self._redis is not None:
            try:
                self._redis.setex(key, ttl_seconds, json.dumps(value))
                return
            except Exception:
                logger.exception("Redis cache set failed for key=%s; falling back to in-memory.", key)

        expires_at = time.monotonic() + float(ttl_seconds)
        with self._lock:
            self._values[key] = (expires_at, value)

    def invalidate_prefix(self, prefix: str) -> None:
        if self._redis is not None:
            try:
                cursor = 0
                pattern = f"{prefix}*"
                while True:
                    cursor, keys = self._redis.scan(cursor=cursor, match=pattern, count=100)
                    if keys:
                        self._redis.delete(*keys)
                    if cursor == 0:
                        break
                return
            except Exception:
                logger.exception("Redis cache prefix invalidation failed for prefix=%s; using in-memory.", prefix)

        with self._lock:
            keys = [key for key in self._values.keys() if key.startswith(prefix)]
            for key in keys:
                self._values.pop(key, None)


cache = TTLCache()
