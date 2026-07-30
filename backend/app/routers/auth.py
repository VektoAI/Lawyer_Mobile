"""Auth routes — signup / login / email-confirm / demo / refresh."""
from __future__ import annotations

import hmac
import json
from html import escape
from urllib.parse import urlencode

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request
from fastapi.responses import HTMLResponse

from app.config import get_settings
from app.deps import DEMO_SALT, DEMO_TOKEN, demo_session_payload
from app.schemas import ConfirmBody, LoginBody, RefreshBody, ResendBody, SignupBody
from app.supabase_client import ensure_profile, fetch_profile, supabase_client

router = APIRouter(tags=["auth"])

_KEEP_EMAILS = {"demo@localhost", "demo@munshi.local"}


def _confirm_redirect_url(request: Request) -> str:
    """Where Supabase's email-confirm link points.

    Our own GET /api/auth/confirm page — an https URL, so it opens reliably in
    every mail client regardless of OS/app-install state (unlike a bare
    casevault:// link, which some clients refuse to render as tappable at
    all). That page verifies the token once, then hands off to the app.
    """
    return str(request.base_url).rstrip("/") + "/api/auth/confirm"


def _is_unconfirmed_error(exc: BaseException) -> bool:
    msg = str(exc).lower()
    return any(
        s in msg
        for s in (
            "email not confirmed",
            "not confirmed",
            "confirm your email",
            "email_not_confirmed",
        )
    )


def _session_payload(user, session, email: str, salt: str | None = None, plan: str = "free"):
    profile = None
    if session and session.access_token:
        profile = fetch_profile(user.id, session.access_token)
    salt = salt or (profile or {}).get("salt") or (user.user_metadata or {}).get("salt")
    plan = (profile or {}).get("plan") or (user.app_metadata or {}).get("plan") or plan
    meta = user.user_metadata or {}
    return {
        "ok": True,
        "token": session.access_token if session else None,
        "refresh_token": session.refresh_token if session else None,
        "user_id": user.id,
        "email": email,
        "salt": salt,
        "plan": plan,
        "display_name": (profile or {}).get("display_name") or meta.get("display_name") or "",
        "enrolment": (profile or {}).get("enrolment") or "",
        "bar_council": (profile or {}).get("bar_council") or "",
        "chamber": (profile or {}).get("chamber") or "",
    }


@router.post("/signup")
def signup(body: SignupBody, request: Request):
    """Create account. Case data stays on the user's device only."""
    email = body.email.strip().lower()
    if email in _KEEP_EMAILS:
        raise HTTPException(400, "Use Sign in with demo@localhost — no email signup for demo")
    if "@" not in email:
        raise HTTPException(400, "valid email required")

    redirect_to = _confirm_redirect_url(request)
    salt = body.salt.strip()
    display_name = (body.display_name or "").strip() or None
    phone = (body.phone or "").strip() or None

    sb = supabase_client()
    try:
        meta = {"salt": salt}
        if display_name:
            meta["display_name"] = display_name
        if phone:
            meta["phone"] = phone
        res = sb.auth.sign_up({
            "email": email,
            "password": body.password,
            "options": {
                "data": meta,
                "email_redirect_to": redirect_to,
            },
        })
    except Exception as exc:
        raise HTTPException(400, str(exc)) from exc

    user = res.user
    session = res.session
    if not user:
        raise HTTPException(400, "signup failed")

    access = session.access_token if session else None
    ensure_profile(user.id, email, salt, access, display_name=display_name, phone=phone)

    if not session:
        return {
            "ok": True,
            "needs_email_confirm": True,
            "user_id": user.id,
            "email": email,
            "salt": salt,
            "display_name": display_name or "",
            "email_redirect_to": redirect_to,
            "message": (
                "Check your email and open the confirmation link, then sign in."
            ),
        }

    out = _session_payload(user, session, email, salt=salt)
    out["needs_email_confirm"] = False
    out["email_redirect_to"] = redirect_to
    out["display_name"] = display_name or (user.user_metadata or {}).get("display_name") or ""
    return out


def _verify_otp_and_confirm(token_hash: str, kind: str):
    """One-time exchange of a Supabase email token_hash for a session.

    Shared by the JSON endpoint (used when the app itself catches a raw
    casevault:// link with a token_hash) and the HTML landing page (the
    normal path — see confirm_email_page). Raises ValueError with a
    user-facing message on any failure; never call this twice with the same
    token_hash, Supabase's OTP tokens are single-use.
    """
    token_hash = token_hash.strip()
    kind = (kind or "signup").strip()
    if not token_hash:
        raise ValueError("This confirmation link is missing its token.")

    sb = supabase_client()
    try:
        res = sb.auth.verify_otp({"token_hash": token_hash, "type": kind})
    except Exception as exc:
        if kind != "email":
            try:
                res = sb.auth.verify_otp({"token_hash": token_hash, "type": "email"})
            except Exception:
                raise ValueError(
                    "This link has expired or was already used."
                ) from exc
        else:
            raise ValueError("This link has expired or was already used.") from exc

    user = res.user
    session = res.session
    if not user or not session:
        raise ValueError("Confirmation did not complete — please sign in instead.")

    email = (user.email or "").lower()
    salt = (user.user_metadata or {}).get("salt")
    if salt:
        ensure_profile(user.id, email, salt, session.access_token)
    return user, session, email, salt


@router.post("/auth/confirm")
def confirm_email(body: ConfirmBody):
    """Exchange Supabase email token_hash for a session (raw casevault:// link, app-side)."""
    try:
        user, session, email, salt = _verify_otp_and_confirm(body.token_hash, body.type)
    except ValueError as exc:
        raise HTTPException(400, str(exc)) from exc
    out = _session_payload(user, session, email, salt=salt)
    out["confirmed"] = True
    return out


_CONFIRM_PAGE_STYLE = """
  :root{color-scheme:light dark}
  body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
    background:#F7F5F0;color:#0F2E27;font:16px/1.5 -apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;
    padding:32px 20px;box-sizing:border-box}
  @media (prefers-color-scheme:dark){body{background:#0C1B17;color:#F2EFE7}}
  .card{max-width:420px;text-align:center}
  .badge{width:56px;height:56px;border-radius:50%;display:flex;align-items:center;justify-content:center;
    margin:0 auto 20px;font-size:28px}
  .ok .badge{background:#E4EEE5;color:#3E6E4E}
  .err .badge{background:#F7E6E3;color:#9A3A38}
  h1{font-size:20px;margin:0 0 10px}
  p{margin:0 0 24px;color:inherit;opacity:.8}
  a.btn{display:inline-block;background:#0F2E27;color:#F7F5F0;text-decoration:none;
    padding:12px 28px;border-radius:8px;font-weight:600;font-size:15px}
  .hint{margin-top:16px;font-size:13px;opacity:.6}
"""


def _confirm_page_html(*, ok: bool, message: str, deep_link: str | None = None) -> str:
    open_app = f'<p><a class="btn" href="{escape(deep_link)}">Open Case Vault</a></p>' if deep_link else ""
    auto_redirect = (
        f"<script>try{{location.replace({json.dumps(deep_link)});}}catch(e){{}}</script>"
        if deep_link
        else ""
    )
    icon = "&#10003;" if ok else "&#33;"
    title = "Email verified" if ok else "Link didn't work"
    return f"""<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex">
<title>{title} — Case Vault</title>
<style>{_CONFIRM_PAGE_STYLE}</style></head>
<body><div class="card {'ok' if ok else 'err'}">
<div class="badge">{icon}</div>
<h1>{escape(title)}</h1>
<p>{escape(message)}</p>
{open_app}
<div class="hint">{"You can close this tab." if ok else "Open the app and tap Resend confirmation email."}</div>
</div>{auto_redirect}</body></html>"""


_CONFIRM_FRAGMENT_FALLBACK_HTML = f"""<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="robots" content="noindex">
<title>Confirming — Case Vault</title>
<style>{_CONFIRM_PAGE_STYLE}</style></head>
<body><div class="card" id="c">
<div class="badge">&hellip;</div>
<h1>Confirming&hellip;</h1>
<p>One moment.</p>
</div>
<script>
(function() {{
  var frag = location.hash ? location.hash.slice(1) : '';
  var params = new URLSearchParams(frag);
  var access = params.get('access_token');
  var el = document.getElementById('c');
  if (access) {{
    var deepLink = 'casevault://auth/confirm#' + frag;
    el.className = 'card ok';
    el.innerHTML = '<div class="badge">&#10003;</div><h1>Email verified</h1>'
      + '<p>Opening the Case Vault app&hellip;</p>'
      + '<p><a class="btn" href="' + deepLink + '">Open Case Vault</a></p>'
      + '<div class="hint">You can close this tab.</div>';
    try {{ location.replace(deepLink); }} catch (e) {{}}
  }} else {{
    var err = params.get('error_description') || params.get('error');
    el.className = 'card err';
    el.innerHTML = '<div class="badge">&#33;</div><h1>Link didn\\'t work</h1>'
      + '<p>' + (err ? err.replace(/\\+/g, ' ') : 'This link has expired or was already used.') + '</p>'
      + '<div class="hint">Open the app and tap Resend confirmation email.</div>';
  }}
}})();
</script>
</body></html>"""


@router.get("/auth/confirm", response_class=HTMLResponse)
def confirm_email_page(token_hash: str = "", otp_type: str = Query("signup", alias="type")):
    """Where the confirmation email link actually points (see _confirm_redirect_url).

    Two ways a request can arrive here, depending on the Supabase email
    template in use:

    1. Custom template with {{ .TokenHash }} in the link — token_hash arrives
       as a query param. We verify it here, server-side, exactly once, then
       hand a ready-to-use session to the app via a casevault:// deep link
       fragment. (Requires a paid Supabase plan or custom SMTP to edit the
       template — see backend/README.md.)
    2. Supabase's *default* {{ .ConfirmationURL }} template (what a free-tier
       project is stuck with) — Supabase verifies server-side itself and
       redirects here with the session already in the URL *fragment*
       (#access_token=...), which a server can never see (fragments never
       reach the server). We render a page whose own JS reads the fragment
       and hands off to the app directly — no token_hash, no server call.

    Either way, tokens only ever travel in the fragment, never a query string
    or server log.
    """
    if not token_hash:
        return HTMLResponse(_CONFIRM_FRAGMENT_FALLBACK_HTML, headers={"Cache-Control": "no-store"})

    try:
        user, session, email, salt = _verify_otp_and_confirm(token_hash, otp_type)
    except ValueError as exc:
        html = _confirm_page_html(ok=False, message=str(exc))
        return HTMLResponse(html, status_code=400, headers={"Cache-Control": "no-store"})

    frag = urlencode({"access_token": session.access_token, "refresh_token": session.refresh_token})
    deep_link = f"casevault://auth/confirm#{frag}"
    html = _confirm_page_html(
        ok=True,
        message=f"{email} is confirmed. Opening the Case Vault app…",
        deep_link=deep_link,
    )
    return HTMLResponse(html, headers={"Cache-Control": "no-store"})


@router.post("/auth/resend-confirm")
def resend_confirm(body: ResendBody, request: Request):
    """Resend signup confirmation email. Sign-in never sends mail."""
    email = body.email.strip().lower()
    if not email or "@" not in email:
        raise HTTPException(400, "valid email required")
    if email in _KEEP_EMAILS:
        raise HTTPException(400, "demo account needs no email — sign in with demo password")

    redirect_to = _confirm_redirect_url(request)
    sb = supabase_client()
    try:
        sb.auth.resend({
            "type": "signup",
            "email": email,
            "options": {"email_redirect_to": redirect_to},
        })
    except Exception as exc:
        raise HTTPException(400, f"could not resend confirmation: {exc}") from exc
    return {
        "ok": True,
        "email": email,
        "email_redirect_to": redirect_to,
        "message": f"Confirmation link resent (should open {redirect_to}). Check inbox/spam.",
    }


@router.post("/login")
def login(body: LoginBody):
    """Email + password → JWT. Does NOT send email."""
    email = body.email.strip().lower()
    if not email or not body.password:
        raise HTTPException(400, "email and password required")

    # Showcase demo: no Supabase account — only while MUNSHI_DEMO=1. When disabled this
    # falls through to the real Supabase attempt below, which fails as invalid credentials
    # (demo@localhost has no Supabase account) without revealing the demo mechanism exists.
    if (
        get_settings().demo_open
        and email in _KEEP_EMAILS
        and body.password == "demo-password-change-me"
    ):
        return demo_session_payload()

    try:
        sb = supabase_client()
    except HTTPException:
        raise
    except Exception as exc:
        print(f"[login] supabase client failed: {exc!r}", flush=True)
        raise HTTPException(503, f"Auth service unavailable: {exc}") from exc

    try:
        res = sb.auth.sign_in_with_password({"email": email, "password": body.password})
    except Exception as exc:
        print(f"[login] supabase error for {email}: {exc!r}", flush=True)
        if _is_unconfirmed_error(exc):
            raise HTTPException(
                403,
                "Email not confirmed yet. Tap “Resend confirmation” on the sign-in screen.",
            ) from exc
        raise HTTPException(401, "invalid email or password") from exc

    try:
        session = res.session
        user = res.user
        if not session or not user:
            print(f"[login] no session for {email}", flush=True)
            raise HTTPException(401, "invalid email or password")

        profile = fetch_profile(user.id, session.access_token)
        salt = (profile or {}).get("salt") or (user.user_metadata or {}).get("salt")
        if not salt:
            raise HTTPException(
                409,
                "Account setup incomplete on the server. Sign up again on this browser, or restore a backup.",
            )
        plan = (profile or {}).get("plan") or (user.app_metadata or {}).get("plan") or "free"
        print(f"[login] ok {email} plan={plan}", flush=True)

        return {
            "ok": True,
            "token": session.access_token,
            "refresh_token": session.refresh_token,
            "user_id": str(user.id),
            "email": email,
            "salt": salt,
            "plan": plan,
        }
    except HTTPException:
        raise
    except Exception as exc:
        # Never leak a bare 500 — surface the reason for local debugging
        print(f"[login] unexpected error for {email}: {exc!r}", flush=True)
        raise HTTPException(500, f"Login failed: {exc}") from exc



@router.post("/auth/demo")
def auth_demo():
    """One-tap showcase chamber. Cases seed locally and stay view-only in the UI.

    Only available while MUNSHI_DEMO=1 — MUST be 0 on any public deployment.
    """
    if not get_settings().demo_open:
        raise HTTPException(403, "demo mode is disabled on this server")
    return demo_session_payload()


@router.post("/auth/refresh")
def refresh(body: RefreshBody):
    refresh_token = body.refresh_token.strip()
    if not refresh_token:
        raise HTTPException(400, "refresh_token required")
    # Demo token is not a Supabase JWT — no refresh needed (only while MUNSHI_DEMO=1;
    # otherwise falls through to a real Supabase refresh attempt, which fails closed).
    if get_settings().demo_open and refresh_token in (DEMO_TOKEN, "demo-local-vault"):
        return {"ok": True, "token": DEMO_TOKEN, "refresh_token": DEMO_TOKEN, "demo": True}
    sb = supabase_client()
    try:
        res = sb.auth.refresh_session(refresh_token)
    except Exception as exc:
        raise HTTPException(401, "refresh failed") from exc
    session = res.session
    if not session:
        raise HTTPException(401, "refresh failed")
    return {
        "ok": True,
        "token": session.access_token,
        "refresh_token": session.refresh_token,
    }


def require_admin_token(x_admin_token: str | None = Header(default=None, alias="X-Admin-Token")):
    """Auth for dev/ops-only routes: valid MUNSHI_ADMIN_TOKEN header, AND demo mode open.

    Defense in depth — either control alone (a leaked token, or MUNSHI_DEMO left on by
    mistake) is not enough on its own to reach the route behind this dependency.
    """
    settings = get_settings()
    if not settings.demo_open:
        raise HTTPException(403, "dev/admin routes are disabled (MUNSHI_DEMO=0)")
    if not settings.admin_token:
        raise HTTPException(503, "Set MUNSHI_ADMIN_TOKEN on the server to enable dev/admin routes")
    if not x_admin_token or not hmac.compare_digest(x_admin_token, settings.admin_token):
        raise HTTPException(401, "invalid admin token")


@router.post("/dev/purge-auth-users")
def purge_auth_users(_auth=Depends(require_admin_token)):
    """Delete every Supabase Auth user except local demo addresses.

    Requires the X-Admin-Token header (MUNSHI_ADMIN_TOKEN) and MUNSHI_DEMO=1, plus
    SUPABASE_SERVICE_ROLE_KEY in backend/.env. Demo login is not in Supabase.
    """
    settings = get_settings()
    if not settings.supabase_service_role_key:
        raise HTTPException(
            503,
            "Add SUPABASE_SERVICE_ROLE_KEY to backend/.env (Supabase → Project Settings → API → service_role), restart, then retry",
        )

    sb = supabase_client(service=True)
    deleted: list[str] = []
    errors: list[str] = []
    page = 1
    per_page = 100
    while True:
        try:
            res = sb.auth.admin.list_users(page=page, per_page=per_page)
        except TypeError:
            res = sb.auth.admin.list_users()
        users = getattr(res, "users", None) or (res if isinstance(res, list) else [])
        if hasattr(res, "users"):
            users = res.users
        elif isinstance(res, dict):
            users = res.get("users") or []
        if not users:
            break
        for u in users:
            email = (getattr(u, "email", None) or (u.get("email") if isinstance(u, dict) else "") or "").lower()
            uid = getattr(u, "id", None) or (u.get("id") if isinstance(u, dict) else None)
            if not uid:
                continue
            if email in _KEEP_EMAILS:
                continue
            try:
                sb.auth.admin.delete_user(uid)
                deleted.append(email or str(uid))
                try:
                    sb.table("profiles").delete().eq("id", str(uid)).execute()
                except Exception:
                    pass
            except Exception as exc:
                errors.append(f"{email or uid}: {exc}")
        if len(users) < per_page:
            break
        page += 1
        if page > 50:
            break

    return {
        "ok": True,
        "deleted": deleted,
        "errors": errors,
        "kept": sorted(_KEEP_EMAILS),
        "note": "demo@localhost is local-only (not in Supabase). Sign in with that + demo-password-change-me.",
    }
