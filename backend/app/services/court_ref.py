"""Shared case-reference normalization (no court adapter imports)."""
from __future__ import annotations

import re


def norm_ref(ref: str) -> str:
    return re.sub(r"[^A-Z0-9]+", " ", (ref or "").upper()).strip()
