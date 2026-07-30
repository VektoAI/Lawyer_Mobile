"""Uvicorn entrypoint: `uvicorn main:app --app-dir backend`

Prefer `app.main:app` once the package is on PYTHONPATH; this shim keeps one command.
"""
from app.main import app

__all__ = ["app"]
