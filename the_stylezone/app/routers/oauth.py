
import logging
import secrets
from typing import Optional
import httpx
from fastapi import APIRouter, Request, HTTPException, status
from fastapi.responses import RedirectResponse, HTMLResponse
from app.config import (
    GOOGLE_CLIENT_ID,
    GOOGLE_CLIENT_SECRET,
    FACEBOOK_CLIENT_ID,
    FACEBOOK_CLIENT_SECRET,
    APP_URL,
    SESSION_COOKIE_NAME,
    SESSION_MAX_AGE,
    DEBUG,
)
from app.database import get_db, query_one, save_db_snapshot
from app.security import create_session, hash_password
from app.routers.public import get_common_context

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["OAuth"])

@router.get("/google")
async def google_login(request: Request):
    """
    Google OAuth 2.0 flow initiation.
    If credentials are not configured in .env, displays clear instructions on how to set them up.
    """
    if not GOOGLE_CLIENT_ID or not GOOGLE_CLIENT_SECRET:
        ctx = get_common_context(request)
        ctx["provider"] = "Google"
        ctx["client_id_var"] = "GOOGLE_CLIENT_ID"
        ctx["secret_var"] = "GOOGLE_CLIENT_SECRET"
        ctx["redirect_uri"] = f"{APP_URL.rstrip('/')}/auth/google/callback"
        return HTMLResponse(content=f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Google OAuth Configuration - The Stylezone</title>
            <link rel="stylesheet" href="/static/css/style.css">
        </head>
        <body class="bg-primary text-primary" style="display:flex; align-items:center; justify-content:center; min-height:100vh; padding:20px;">
            <div class="card" style="max-width:600px; width:100%; padding:30px; border:1px solid var(--gold); border-radius:12px; background:var(--bg-card);">
                <div style="text-align:center; margin-bottom:20px;">
                    <h2 style="color:var(--gold); font-family:var(--font-heading); margin-bottom:8px;">Google Sign-In Configuration</h2>
                    <p style="color:var(--text-muted); font-size:14px;">The Stylezone OAuth Architecture</p>
                </div>
                <div class="alert alert-info" style="margin-bottom:20px;">
                    <p><strong>Notice:</strong> Google OAuth client credentials have not been configured in your <code>.env</code> file yet.</p>
                </div>
                <div style="font-size:14px; line-height:1.6; color:var(--text-secondary); margin-bottom:24px;">
                    <p>To enable <strong>Continue with Google</strong> in production:</p>
                    <ol style="margin-left:20px; margin-top:10px;">
                        <li>Go to <a href="https://console.cloud.google.com/apis/credentials" target="_blank" style="color:var(--gold);">Google Cloud Console &rarr; Credentials</a>.</li>
                        <li>Create an OAuth 2.0 Client ID (Web Application).</li>
                        <li>Add Authorized Redirect URI: <code>{ctx['redirect_uri']}</code></li>
                        <li>Copy the Client ID and Client Secret into your <code>.env</code> file:
                            <pre style="background:#000; padding:10px; border-radius:6px; margin-top:8px; color:var(--gold-light);">GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret</pre>
                        </li>
                    </ol>
                </div>
                <div style="text-align:center;">
                    <a href="/login" class="btn btn-primary">Back to Login</a>
                </div>
            </div>
        </body>
        </html>
        """)

    redirect_uri = f"{APP_URL.rstrip('/')}/auth/google/callback"
    google_url = (
        f"https://accounts.google.com/o/oauth2/v2/auth?"
        f"client_id={GOOGLE_CLIENT_ID}&"
        f"response_type=code&"
        f"scope=openid%20email%20profile&"
        f"redirect_uri={redirect_uri}&"
        f"state=stylezone_google&"
        f"prompt=select_account"
    )
    return RedirectResponse(google_url)

@router.get("/google/callback")
async def google_callback(
    request: Request,
    code: Optional[str] = None,
    error: Optional[str] = None,
    state: Optional[str] = None
):
    """
    Google OAuth 2.0 callback handler.
    Exchanges code for tokens, verifies profile, securely links or creates customer account,
    creates database session, and sets stylezone_session HTTP-only cookie before redirecting to /account.
    """
    if error:
        logger.warning("Google OAuth returned error: %s", error)
        return RedirectResponse("/login?error=Google+sign-in+was+cancelled+or+denied", status_code=status.HTTP_303_SEE_OTHER)

    if not code:
        logger.warning("Google OAuth callback invoked without authorization code")
        return RedirectResponse("/login?error=Authorization+code+missing+from+Google", status_code=status.HTTP_303_SEE_OTHER)

    if not GOOGLE_CLIENT_ID or not GOOGLE_CLIENT_SECRET:
        logger.error("Google OAuth credentials missing during callback handling")
        return RedirectResponse("/login?error=Google+OAuth+is+not+properly+configured", status_code=status.HTTP_303_SEE_OTHER)

    redirect_uri = f"{APP_URL.rstrip('/')}/auth/google/callback"

    # Step 1: Exchange authorization code for tokens
    token_url = "https://oauth2.googleapis.com/token"
    token_data = {
        "code": code,
        "client_id": GOOGLE_CLIENT_ID,
        "client_secret": GOOGLE_CLIENT_SECRET,
        "redirect_uri": redirect_uri,
        "grant_type": "authorization_code",
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as http_client:
            token_response = await http_client.post(
                token_url,
                data=token_data,
                headers={"Accept": "application/json"}
            )
    except Exception as exc:
        logger.error("Network error during Google token exchange: %s", type(exc).__name__)
        return RedirectResponse("/login?error=Unable+to+connect+to+Google.+Please+try+again.", status_code=status.HTTP_303_SEE_OTHER)

    if token_response.status_code != 200:
        logger.error("Google token exchange failed with HTTP %d: %s", token_response.status_code, token_response.text[:200])
        return RedirectResponse("/login?error=Failed+to+exchange+authorization+code+with+Google", status_code=status.HTTP_303_SEE_OTHER)

    tokens = token_response.json()
    access_token = tokens.get("access_token")
    if not access_token:
        logger.error("No access_token returned by Google token endpoint")
        return RedirectResponse("/login?error=Invalid+token+response+from+Google", status_code=status.HTTP_303_SEE_OTHER)

    # Step 2: Fetch verified profile information from Google userinfo endpoint
    userinfo_url = "https://www.googleapis.com/oauth2/v3/userinfo"
    try:
        async with httpx.AsyncClient(timeout=15.0) as http_client:
            userinfo_response = await http_client.get(
                userinfo_url,
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Accept": "application/json"
                }
            )
    except Exception as exc:
        logger.error("Network error fetching Google userinfo: %s", type(exc).__name__)
        return RedirectResponse("/login?error=Unable+to+retrieve+profile+from+Google.+Please+try+again.", status_code=status.HTTP_303_SEE_OTHER)

    if userinfo_response.status_code != 200:
        logger.error("Google userinfo request failed with HTTP %d", userinfo_response.status_code)
        return RedirectResponse("/login?error=Failed+to+retrieve+profile+information+from+Google", status_code=status.HTTP_303_SEE_OTHER)

    profile = userinfo_response.json()
    google_sub = profile.get("sub")
    email = profile.get("email")
    email_verified = profile.get("email_verified", False)
    name = profile.get("name") or profile.get("given_name") or ""

    if not email:
        logger.error("Google profile did not contain an email address")
        return RedirectResponse("/login?error=Google+profile+did+not+provide+an+email+address", status_code=status.HTTP_303_SEE_OTHER)

    if not email_verified:
        logger.warning("Google account email is unverified for %s", email)
        return RedirectResponse("/login?error=Your+Google+email+address+is+not+verified", status_code=status.HTTP_303_SEE_OTHER)

    email_clean = email.strip().lower()

    # Step 3: Find customer by OAuth provider/provider ID or verified email
    user = None
    if google_sub:
        user = query_one(
            "SELECT id, full_name, email, role, oauth_provider, oauth_id FROM users WHERE oauth_provider = 'google' AND oauth_id = ?",
            (str(google_sub),)
        )

    # If not found by google_sub, check if email already exists
    if not user:
        user = query_one(
            "SELECT id, full_name, email, role, oauth_provider, oauth_id FROM users WHERE email = ?",
            (email_clean,)
        )
        if user:
            # Step 4: Securely link Google to that existing account instead of creating a duplicate
            with get_db() as conn:
                conn.execute(
                    """
                    UPDATE users
                    SET oauth_provider = 'google', oauth_id = ?, updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                    """,
                    (str(google_sub) if google_sub else None, user["id"])
                )
            save_db_snapshot()
            user = query_one(
                "SELECT id, full_name, email, role, oauth_provider, oauth_id FROM users WHERE id = ?",
                (user["id"],)
            )

    # Step 5: Otherwise create a new customer account using Google profile name/email
    if not user:
        display_name = name.strip() if name and name.strip() else email_clean.split("@")[0]
        # Secure random password hash to fulfill NOT NULL constraint safely
        random_password_hash = hash_password(secrets.token_urlsafe(32))
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO users (full_name, email, password_hash, role, oauth_provider, oauth_id, created_at, updated_at)
                VALUES (?, ?, ?, 'customer', 'google', ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                """,
                (display_name, email_clean, random_password_hash, str(google_sub) if google_sub else None)
            )
            new_user_id = cursor.lastrowid
        save_db_snapshot()
        user = query_one(
            "SELECT id, full_name, email, role, oauth_provider, oauth_id FROM users WHERE id = ?",
            (new_user_id,)
        )

    # Step 6: Call existing create_session(user["id"], user["role"])
    session_id = create_session(user["id"], user["role"])

    # Step 7: Set SESSION_COOKIE_NAME cookie using standard secure cookie settings
    redirect_resp = RedirectResponse("/account", status_code=status.HTTP_303_SEE_OTHER)
    is_secure = (request.url.scheme == "https") or (request.headers.get("x-forwarded-proto") == "https") or (not DEBUG)

    redirect_resp.set_cookie(
        key=SESSION_COOKIE_NAME,
        value=session_id,
        max_age=SESSION_MAX_AGE,
        httponly=True,
        samesite="lax",
        secure=is_secure
    )

    # Step 8: Redirect to /account
    return redirect_resp

@router.get("/facebook")
async def facebook_login(request: Request):
    """Facebook OAuth flow."""
    if not FACEBOOK_CLIENT_ID or not FACEBOOK_CLIENT_SECRET:
        redirect_uri = f"{APP_URL.rstrip('/')}/auth/facebook/callback"
        return HTMLResponse(content=f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Facebook Login Configuration - The Stylezone</title>
            <link rel="stylesheet" href="/static/css/style.css">
        </head>
        <body class="bg-primary text-primary" style="display:flex; align-items:center; justify-content:center; min-height:100vh; padding:20px;">
            <div class="card" style="max-width:600px; width:100%; padding:30px; border:1px solid var(--gold); border-radius:12px; background:var(--bg-card);">
                <div style="text-align:center; margin-bottom:20px;">
                    <h2 style="color:var(--gold); font-family:var(--font-heading); margin-bottom:8px;">Facebook Login Configuration</h2>
                    <p style="color:var(--text-muted); font-size:14px;">The Stylezone OAuth Architecture</p>
                </div>
                <div class="alert alert-info" style="margin-bottom:20px;">
                    <p><strong>Notice:</strong> Facebook App credentials have not been configured in your <code>.env</code> file yet.</p>
                </div>
                <div style="font-size:14px; line-height:1.6; color:var(--text-secondary); margin-bottom:24px;">
                    <p>To enable <strong>Continue with Facebook</strong>:</p>
                    <ol style="margin-left:20px; margin-top:10px;">
                        <li>Go to <a href="https://developers.facebook.com" target="_blank" style="color:var(--gold);">Meta for Developers</a>.</li>
                        <li>Create an App and add Facebook Login.</li>
                        <li>Add OAuth Redirect URI: <code>{redirect_uri}</code></li>
                        <li>Add to <code>.env</code>:
                            <pre style="background:#000; padding:10px; border-radius:6px; margin-top:8px; color:var(--gold-light);">FACEBOOK_CLIENT_ID=your-facebook-app-id
FACEBOOK_CLIENT_SECRET=your-facebook-app-secret</pre>
                        </li>
                    </ol>
                </div>
                <div style="text-align:center;">
                    <a href="/login" class="btn btn-primary">Back to Login</a>
                </div>
            </div>
        </body>
        </html>
        """)

    redirect_uri = f"{APP_URL.rstrip('/')}/auth/facebook/callback"
    fb_url = (
        f"https://www.facebook.com/v16.0/dialog/oauth?"
        f"client_id={FACEBOOK_CLIENT_ID}&"
        f"redirect_uri={redirect_uri}&"
        f"scope=email,public_profile"
    )
    return RedirectResponse(fb_url)

@router.get("/facebook/callback")
async def facebook_callback(request: Request, code: str = None, error: str = None):
    if error or not code:
        return RedirectResponse("/login?error=Facebook+login+cancelled", status_code=status.HTTP_303_SEE_OTHER)
    return RedirectResponse("/account", status_code=status.HTTP_303_SEE_OTHER)

@router.get("/api/auth/oauth-status")
async def oauth_status():
    return {
        "google_enabled": bool(GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET),
        "facebook_enabled": bool(FACEBOOK_CLIENT_ID and FACEBOOK_CLIENT_SECRET)
    }
