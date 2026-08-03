"""Production-safe rate limiting — slowapi/limits with the default in-memory
store (no Redis or other external service; this is a single-instance Render
deployment, so per-process storage is the correct scope, not a limitation).
See config.py for the configurable per-route limit strings, and factory.py
for how this attaches to the app and how 429s are rendered.
"""
from __future__ import annotations

from fastapi import Request
from fastapi.responses import JSONResponse
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address


def client_ip_key(request: Request) -> str:
    """Client IP for rate limiting.

    Render (and any reverse proxy in front of this API) terminates TLS and
    forwards requests from its own internal address, so
    ``request.client.host`` — what slowapi's default key function uses —
    would be the proxy's IP for every request, collapsing every real client
    into one shared bucket. Trust `X-Forwarded-For`'s first hop (the
    original client; the proxy appends its own IP after it) instead, and
    fall back to the direct peer address when there's no proxy in front
    (local dev, tests).
    """
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return get_remote_address(request)


def account_key(request: Request) -> str:
    """Per-account limiting for already-authenticated routes.

    Keyed on the bearer token itself so distinct accounts get independent
    budgets, rather than one budget shared by every user behind the same
    NAT/proxy IP. Falls back to the IP key if there's no bearer token —
    defense in depth only; the route's own auth dependency already rejects
    that case.
    """
    auth = request.headers.get("authorization", "")
    if auth.startswith("Bearer "):
        return f"acct:{auth[7:].strip()}"
    return f"ip:{client_ip_key(request)}"



# headers_enabled defaults to False in slowapi — without it, no
# X-RateLimit-*/Retry-After headers are ever added to a 429 response.
limiter = Limiter(key_func=client_ip_key, headers_enabled=True)


def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    """429 response in this API's own `{"detail": ...}` shape (matching every
    other error response here) instead of slowapi's default `{"error": ...}`
    — still carries the standard X-RateLimit-*/Retry-After headers via the
    limiter's own header injector, same mechanism slowapi's default handler
    uses internally.
    """
    response = JSONResponse({"detail": f"Rate limit exceeded: {exc.detail}"}, status_code=429)
    return request.app.state.limiter._inject_headers(response, request.state.view_rate_limit)
