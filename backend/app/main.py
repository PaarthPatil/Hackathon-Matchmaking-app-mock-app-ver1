import logging
import time

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.routes import admin, auth, chat, community, hackathon, notification, profile, team
from app.core.config import settings
from app.core.security import verify_bearer_authorization


logging.basicConfig(
    level=settings.log_level,
    format="%(asctime)s | %(levelname)s | %(name)s | %(message)s",
)
logger = logging.getLogger("catalyst-backend")

app = FastAPI(title="Catalyst Backend", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins if settings.cors_origins != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def request_logger(request: Request, call_next):
    start = time.perf_counter()
    user_id = "anonymous"
    user_email = ""
    authorization = request.headers.get("Authorization")
    if authorization:
        try:
            current_user = verify_bearer_authorization(authorization)
            request.state.current_user = current_user
            user_id = current_user["user_id"]
            user_email = current_user.get("email", "")
        except Exception:
            user_id = "unauthenticated"

    logger.info(
        "Incoming request | method=%s path=%s user_id=%s email=%s",
        request.method,
        request.url.path,
        user_id,
        user_email,
    )
    try:
        response = await call_next(request)
        elapsed_ms = (time.perf_counter() - start) * 1000
        logger.info(
            "Completed request | method=%s path=%s user_id=%s email=%s status=%s duration_ms=%.2f",
            request.method,
            request.url.path,
            user_id,
            user_email,
            response.status_code,
            elapsed_ms,
        )
        return response
    except Exception:
        logger.exception(
            "Unhandled request error | method=%s path=%s user_id=%s",
            request.method,
            request.url.path,
            user_id,
        )
        raise


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    error_detail = exc.detail if isinstance(exc.detail, str) else "Request failed."
    logger.warning(
        "HTTP exception | path=%s status=%s detail=%s",
        request.url.path,
        exc.status_code,
        error_detail,
    )
    # Always return consistent error format
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": error_detail, "status_code": exc.status_code},
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    logger.warning("Validation error | path=%s errors=%s", request.url.path, exc.errors())
    return JSONResponse(
        status_code=400,
        content={
            "error": "Invalid input",
            "details": exc.errors(),
            "status_code": 400,
        },
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.exception("Global exception | path=%s", request.url.path)
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "status_code": 500},
    )


app.include_router(auth.router, prefix="/api/v1")
app.include_router(profile.router, prefix="/api/v1")
app.include_router(hackathon.router, prefix="/api/v1")
app.include_router(team.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")
app.include_router(community.router, prefix="/api/v1")
app.include_router(notification.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")
