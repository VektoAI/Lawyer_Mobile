"""Shared pytest fixtures.

Rate limiting (app/rate_limit.py) is always on — deliberately not disabled
in tests, so the suite exercises real behavior — but its in-memory counters
persist for the life of the process (one `Limiter` instance shared by every
test via the module-level `TestClient(app)` in each test file). Without a
reset between tests, one test exhausting a budget would leak into an
unrelated, later test hitting the same endpoint. Autouse so every test file
gets a clean slate without having to remember to ask for it.
"""
from __future__ import annotations

import pytest

from app.rate_limit import limiter


@pytest.fixture(autouse=True)
def _reset_rate_limits():
    limiter.reset()
    yield
    limiter.reset()
