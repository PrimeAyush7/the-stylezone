from fastapi import APIRouter, Request, HTTPException, status
from fastapi.responses import RedirectResponse, HTMLResponse
from app.config import GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, FACEBOOK_CLIENT_ID, FACEBOOK_CLIENT_SECRET, APP_URL
from app.routers.public import get_common_context

router = APIRouter(prefix="/auth", tags=["OAuth"])

@router.get("/google")
async def google_login(request: Request):
    """
    Google OAuth 2.0 flow.
    If credentials are not configured in .env, displays clear instructions on how to set them up.
    """
    if not GOOGLE_CLIENT_ID or not GOOGLE_CLIENT_SECRET:
        ctx = get_common_context(request)
        ctx["provider"] = "Google"
        ctx["client_id_var"] = "GOOGLE_CLIENT_ID"
        ctx["secret_var"] = "GOOGLE_CLIENT_SECRET"
        ctx["redirect_uri"] = f"{APP_URL}/auth/google/callback"
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

    # When configured: redirect to Google accounts
    redirect_uri = f"{APP_URL}/auth/google/callback"
    google_url = (
        f"https://accounts.google.com/o/oauth2/v2/auth?"
        f"client_id={GOOGLE_CLIENT_ID}&"
        f"response_type=code&"
        f"scope=openid%20email%20profile&"
        f"redirect_uri={redirect_uri}&"
        f"state=stylezone_google"
    )
    return RedirectResponse(google_url)

@router.get("/google/callback")
async def google_callback(request: Request, code: str = None, error: str = None):
    if error or not code:
        return RedirectResponse("/login?error=Google+login+cancelled")
    # In production with internet, exchange code for tokens via Google OAuth token endpoint
    return RedirectResponse("/account")

@router.get("/facebook")
async def facebook_login(request: Request):
    """Facebook OAuth flow."""
    if not FACEBOOK_CLIENT_ID or not FACEBOOK_CLIENT_SECRET:
        redirect_uri = f"{APP_URL}/auth/facebook/callback"
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

    redirect_uri = f"{APP_URL}/auth/facebook/callback"
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
        return RedirectResponse("/login?error=Facebook+login+cancelled")
    return RedirectResponse("/account")

@router.get("/api/auth/oauth-status")
async def oauth_status():
    return {
        "google_enabled": bool(GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET),
        "facebook_enabled": bool(FACEBOOK_CLIENT_ID and FACEBOOK_CLIENT_SECRET)
    }
