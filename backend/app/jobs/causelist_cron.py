"""CLI: python -m app.jobs.causelist_cron"""
from __future__ import annotations

import json
import os
import sys


def main() -> int:
    if not (os.environ.get("MUNSHI_CRON_SECRET") or os.environ.get("MUNSHI_ADMIN_TOKEN")):
        print("Set MUNSHI_CRON_SECRET or MUNSHI_ADMIN_TOKEN", file=sys.stderr)
        return 1
    from app.services.causelist_inbox import run_causelist_cron

    result = run_causelist_cron()
    print(json.dumps(result, indent=2))
    return 0 if result.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
