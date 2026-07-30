"""FastAPI app factory — API-only (mobile) or API + legacy PWA (web)."""
from __future__ import annotations

import logging
import time

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from app.config import get_settings
from app.routers import auth, billing, courts, cron, me, system

log = logging.getLogger("munshi.access")


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

    @application.middleware("http")
    async def access_log(request: Request, call_next):
        started = time.perf_counter()
        response = await call_next(request)
        if request.url.path.startswith("/api") or request.url.path in ("/healthz", "/"):
            ms = (time.perf_counter() - started) * 1000
            print(
                f"{request.method} {request.url.path} -> {response.status_code} ({ms:.0f}ms)",
                flush=True,
            )
        return response

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

    return application
