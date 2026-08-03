"""FastAPI app factory — API-only (mobile) or API + legacy PWA (web)."""
from __future__ import annotations

import logging
import time
import uuid

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.config import get_settings
from app.logging_config import configure_logging, request_id_var
from app.rate_limit import limiter, rate_limit_exceeded_handler
from app.routers import auth, billing, courts, cron, me, system

configure_logging()
log = logging.getLogger("munshi.access")
startup_log = logging.getLogger("munshi.startup")


def create_app(*, serve_ui: bool | None = None) -> FastAPI:
    settings = get_settings()
    ui_enabled = settings.serve_ui if serve_ui is None else serve_ui

    application = FastAPI(
        title="Case Vault API",
        description=(
            "Auth, billing, and court-metadata API. "
            "Case / fee / document data stays encrypted on the device — never stored here."
        ),
        version="1.0.0",
        docs_url="/api/docs" if settings.openapi_enabled else None,
        redoc_url="/api/redoc" if settings.openapi_enabled else None,
        openapi_url="/api/openapi.json" if settings.openapi_enabled else None,
    )

    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Rate limiting — see app/rate_limit.py for the key functions and
    # config.py for the configurable per-route limit strings. `enabled` is
    # read fresh here (not cached on the Limiter across settings changes)
    # so ops can flip MUNSHI_RATE_LIMIT_ENABLED without a code change.
    limiter.enabled = settings.rate_limit_enabled
    application.state.limiter = limiter
    application.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)
    application.add_middleware(SlowAPIMiddleware)

    @application.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        """Last-resort safety net for anything that isn't already an
        HTTPException (which FastAPI's own, more specific handler continues
        to handle — this one is never consulted for those). Guarantees the
        same {"detail": ...} envelope every other error in this API already
        uses, and never leaks the exception message/traceback to the client
        — full detail already went to the structured log via the
        request_context middleware above."""
        return JSONResponse({"detail": "Internal server error"}, status_code=500)

    @application.middleware("http")
    async def request_context(request: Request, call_next):
        """Assigns/propagates a request id for log correlation, times the
        request, and logs one structured line per request — replacing the
        old bare print() access log. Reuses an incoming X-Request-ID if the
        client/proxy already set one, so a request can be traced end-to-end
        across services; otherwise generates one and echoes it back."""
        req_id = request.headers.get("x-request-id") or str(uuid.uuid4())
        token = request_id_var.set(req_id)
        started = time.perf_counter()
        try:
            try:
                response = await call_next(request)
            except Exception:
                duration_ms = (time.perf_counter() - started) * 1000
                log.exception(
                    "unhandled exception",
                    extra={"method": request.method, "path": request.url.path, "duration_ms": round(duration_ms, 1)},
                )
                raise

            duration_ms = (time.perf_counter() - started) * 1000
            response.headers["X-Request-ID"] = req_id
            slow = duration_ms > settings.slow_request_threshold_ms
            if response.status_code >= 500:
                level = logging.ERROR
            elif response.status_code >= 400 or slow:
                level = logging.WARNING
            else:
                level = logging.INFO
            log.log(
                level,
                "request",
                extra={
                    "method": request.method,
                    "path": request.url.path,
                    "status": response.status_code,
                    "duration_ms": round(duration_ms, 1),
                    "slow": slow,
                },
            )
            return response
        finally:
            request_id_var.reset(token)

    application.include_router(system.router)
    application.include_router(auth.router, prefix="/api")
    application.include_router(me.router, prefix="/api")
    application.include_router(billing.router, prefix="/api")
    application.include_router(courts.router, prefix="/api")
    application.include_router(cron.router, prefix="/api")

    if ui_enabled:
        ui = settings.ui_dir
        if ui.is_dir():

            @application.get("/")
            def root():
                return FileResponse(ui / "index.html")

            @application.get("/index.html")
            def index_html():
                return FileResponse(ui / "index.html")

            application.mount("/", StaticFiles(directory=str(ui), html=True), name="ui")
        else:
            log.warning("MUNSHI_SERVE_UI=1 but UI dir missing: %s", ui)
    else:

        @application.get("/")
        def root_api_only():
            return JSONResponse(
                {
                    "ok": True,
                    "mode": "api-only",
                    "hint": "Flutter mobile client — see /healthz and /api/docs",
                }
            )

    # Startup diagnostics — a structured summary of effective config at boot,
    # deliberately containing no secret *values* (booleans/flags only), so
    # it's always safe to ship to whatever log viewer Render (or any other
    # host) is pointed at. A misconfigured deploy should be loud in the boot
    # log rather than only surfacing on the first real request.
    startup_log.info(
        "backend starting",
        extra={
            "mode": "api-and-legacy-pwa" if ui_enabled else "api-only",
            "demo_open": settings.demo_open,
            "supabase_configured": settings.supabase_configured,
            "rate_limit_enabled": settings.rate_limit_enabled,
            "cron_configured": bool(settings.cron_secret),
            "stripe_configured": bool(settings.stripe_webhook_secret),
            "admin_token_configured": bool(settings.admin_token),
        },
    )
    if not settings.demo_open and not settings.supabase_configured:
        startup_log.error(
            "MUNSHI_DEMO=0 and Supabase is not configured — every real "
            "authenticated request will fail with 503 until SUPABASE_URL "
            "and SUPABASE_ANON_KEY are set"
        )
    if not settings.cron_secret:
        startup_log.warning(
            "no MUNSHI_CRON_SECRET or MUNSHI_ADMIN_TOKEN set — /api/cron/* routes are disabled (503)"
        )
    if not settings.stripe_webhook_secret:
        startup_log.warning(
            "STRIPE_WEBHOOK_SECRET not set — /api/stripe/webhook fails closed (503); billing plan updates are disabled"
        )

    return application
