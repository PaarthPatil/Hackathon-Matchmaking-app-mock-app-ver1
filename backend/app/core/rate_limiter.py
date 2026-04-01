from __future__ import annotations

import logging
import threading
import time
from collections import defaultdict, deque

from fastapi import HTTPException, status

from app.core.config import settings

logger = logging.getLogger(__name__)

try:
    from redis import Redis
except Exception:  # pragma: no cover - optional dependency fallback
    Redis = None  # type: ignore[assignment]


class InMemoryRateLimiter:
    def __init__(self) -> None:
        self._events: dict[str, deque[float]] = defaultdict(deque)
        self._lock = threading.Lock()
        self._redis = self._create_redis_client()

    def _create_redis_client(self) -> Redis | None:
        if not settings.redis_url or Redis is None:
            return None
        try:
            return Redis.from_url(settings.redis_url, decode_responses=True)
        except Exception:
            logger.exception(
                "Failed to initialize Redis rate limiter; falling back to in-memory limiter."
            )
            return None

    def check(self, user_id: str, action: str, limit: int, window_seconds: int) -> None:
        if self._redis is not None:
            redis_key = f"ratelimit:{action}:{user_id}"
            try:
                current = int(self._redis.incr(redis_key))
                if current == 1:
                    self._redis.expire(redis_key, window_seconds)
                if current > limit:
                    raise HTTPException(
                        status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                        detail=f"Rate limit exceeded for {action}. Try again later.",
                    )
                return
            except HTTPException:
                raise
            except Exception:
                logger.exception(
                    "Redis rate-limit check failed for key=%s; falling back to in-memory.", redis_key
                )

        now = time.monotonic()
        key = f"{action}:{user_id}"

        with self._lock:
            queue = self._events[key]
            window_start = now - float(window_seconds)
            while queue and queue[0] < window_start:
                queue.popleft()

            if len(queue) >= limit:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail=f"Rate limit exceeded for {action}. Try again later.",
                )

            queue.append(now)


rate_limiter = InMemoryRateLimiter()
