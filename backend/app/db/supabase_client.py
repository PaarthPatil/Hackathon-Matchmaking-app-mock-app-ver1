from supabase import Client, create_client

from app.core.config import settings


if not settings.supabase_url or not settings.supabase_service_role_key:
    raise RuntimeError(
        "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set."
    )

supabase: Client = create_client(settings.supabase_url, settings.supabase_service_role_key)
