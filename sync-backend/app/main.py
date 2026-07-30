"""Mobile sync-relay API — standalone from backend/app/main.py (which keeps
serving the PWA). See mobile/README.md and ARCHITECTURE.md §12 for why this
is a separate process.
"""
from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import sync, system


def create_app() -> FastAPI:
    settings = get_settings()
    application = FastAPI(
        title="Munshi mobile sync relay",
        description=(
            "Ciphertext event push/pull for the Flutter app. Never stores or "
            "reads plaintext case data — see CLAUDE.md invariant 9."
        ),
        version="0.1.0",
        docs_url="/api/docs",
        redoc_url="/api/redoc",
        openapi_url="/api/openapi.json",
    )

    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    application.include_router(system.router)
    application.include_router(sync.router)

    return application


app = create_app()
