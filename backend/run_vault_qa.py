"""Run vault CRUD QA against a live Munshi server (Playwright)."""
from __future__ import annotations

import json
import sys
import urllib.request

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:4173"


def check_api():
    print("=== Live API ===")
    with urllib.request.urlopen(BASE + "/healthz") as r:
        health = json.loads(r.read())
    print("healthz:", health)
    assert health.get("ok") and health.get("mode") == "auth-billing-only"

    req = urllib.request.Request(BASE + "/api/auth/demo", method="POST", data=b"{}", headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        demo = json.loads(r.read())
    print("demo:", {k: demo[k] for k in ("ok", "token", "plan", "demo") if k in demo})
    assert demo.get("token")

    req = urllib.request.Request(
        BASE + "/api/me/subscription",
        headers={"Authorization": "Bearer " + demo["token"]},
    )
    with urllib.request.urlopen(req) as r:
        me = json.loads(r.read())
    print("me:", me)
    print("API OK\n")


def check_vault_browser():
    print("=== Browser vault CRUD (/qa-vault.html) ===")
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("Playwright not installed — run: .venv\\Scripts\\pip install playwright && .venv\\Scripts\\playwright install chromium")
        print("Then re-run this script. Or open", BASE + "/qa-vault.html", "manually.")
        return 2

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(BASE + "/qa-vault.html", wait_until="networkidle", timeout=120_000)
        page.wait_for_function("() => window.__QA__", timeout=120_000)
        result = page.evaluate("() => window.__QA__")
        log = page.inner_text("#log")
        print(log.encode("ascii", "replace").decode("ascii"))
        print("\n__QA__:", result)
        browser.close()
        return 0 if result and result.get("ok") else 1


if __name__ == "__main__":
    check_api()
    code = check_vault_browser()
    sys.exit(code)
