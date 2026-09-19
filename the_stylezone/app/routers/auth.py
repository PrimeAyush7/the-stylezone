import re
import secrets
import logging
from datetime import datetime, timedelta
from fastapi import APIRouter, Request, Response, Form, HTTPException, status, Depends
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from pathlib import Path
from typing import Optional
from app.templates_engine import Jinja2Templates
from app.database import query_one, execute_write, execute_query, get_db, save_db_snapshot
from app.security import (
    hash_password, verify_password, hash_token, create_session, destroy_session,
    invalidate_user_sessions, get_current_user, check_login_rate_limit,
    record_failed_login, clear_failed_logins
)
from app.config import SESSION_COOKIE_NAME, SESSION_MAX_AGE, DEBUG, APP_URL
from app.csrf import validate_csrf
from app.routers.public import get_common_context

logger = logging.getLogger("stylezone.auth")
templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))
router = APIRouter(tags=["Authentication"])

EMAIL_REGEX = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"

@router.get("/login", response_class=HTMLResponse)
async def login_page(request: Request, return_to: Optional[str] = None):
    user = get_current_user(request)
    if user:
        target = return_to if return_to and return_to.startswith("/") else ("/admin" if user["role"] == "admin" else "/account")
        return RedirectResponse(target, status_code=status.HTTP_302_FOUND)
    ctx = get_common_context(request)
    ctx["return_to"] = return_to or ""
    ctx["error"] = None
    return templates.TemplateResponse(
        request=request,
        name="auth/login.html",
        context=ctx
    )

@router.post("/login", response_class=HTMLResponse)
async def login_post(
    request: Request,
    response: Response,
    email: str = Form(...),
    password: str = Form(...),
    csrf_token: Optional[str] = Form(None),
    return_to: Optional[str] = Form(None)
):
    await validate_csrf(request, csrf_token)
    ctx = get_common_context(request)
    email_clean = email.strip().lower()
    ctx["return_to"] = return_to or ""

    # Rate limiting protection
    client_ip = request.client.host if request.client else "unknown"
    rate_limit_key = f"login:{client_ip}:{email_clean}"
    try:
        check_login_rate_limit(rate_limit_key, max_attempts=5, window_seconds=300)
    except HTTPException as he:
        ctx["error"] = he.detail
        return templates.TemplateResponse(
            request=request,
            name="auth/login.html",
            context=ctx,
            status_code=he.status_code
        )

    if not email_clean or not password:
        ctx["error"] = "Please provide both email and password."
        return templates.TemplateResponse(
            request=request,
            name="auth/login.html",
            context=ctx,
            status_code=status.HTTP_400_BAD_REQUEST
        )

    user = query_one("SELECT * FROM users WHERE email = ?", (email_clean,))
    if not user or not verify_password(password, user["password_hash"]):
        record_failed_login(rate_limit_key)
        ctx["error"] = "Invalid email or password. Please try again."
        return templates.TemplateResponse(
            request=request,
            name="auth/login.html",
            context=ctx,
            status_code=status.HTTP_401_UNAUTHORIZED
        )

    clear_failed_logins(rate_limit_key)
    session_id = create_session(user["id"], user["role"])
    target = return_to if return_to and return_to.startswith("/") else ("/admin" if user["role"] == "admin" else "/account")
    
    redirect_resp = RedirectResponse(target, status_code=status.HTTP_303_SEE_OTHER)
    redirect_resp.set_cookie(
        key=SESSION_COOKIE_NAME,
        value=session_id,
        max_age=SESSION_MAX_AGE,
        httponly=True,
        samesite="lax",
        secure=request.url.scheme == "https"
    )
    return redirect_resp

@router.get("/register", response_class=HTMLResponse)
async def register_page(request: Request, return_to: Optional[str] = None):
    user = get_current_user(request)
    if user:
        return RedirectResponse("/account", status_code=status.HTTP_302_FOUND)
    ctx = get_common_context(request)
    ctx["return_to"] = return_to or ""
    ctx["error"] = None
    return templates.TemplateResponse(
        request=request,
        name="auth/register.html",
        context=ctx
    )

@router.post("/register", response_class=HTMLResponse)
async def register_post(
    request: Request,
    response: Response,
    full_name: str = Form(...),
    email: str = Form(...),
    password: str = Form(...),
    confirm_password: str = Form(...),
    csrf_token: Optional[str] = Form(None),
    phone: Optional[str] = Form(None),
    return_to: Optional[str] = Form(None)
):
    await validate_csrf(request, csrf_token)
    ctx = get_common_context(request)
    ctx["return_to"] = return_to or ""
    full_name_clean = full_name.strip()
    email_clean = email.strip().lower()
    phone_clean = phone.strip() if phone else ""

    if len(full_name_clean) < 2:
        ctx["error"] = "Please enter your full name (at least 2 characters)."
        return templates.TemplateResponse(
            request=request,
            name="auth/register.html",
            context=ctx,
            status_code=status.HTTP_400_BAD_REQUEST
        )

    if not re.match(EMAIL_REGEX, email_clean):
        ctx["error"] = "Please enter a valid email address."
        return templates.TemplateResponse(
            request=request,
            name="auth/register.html",
            context=ctx,
            status_code=status.HTTP_400_BAD_REQUEST
        )

    if len(password) < 6:
        ctx["error"] = "Password must be at least 6 characters long."
        return templates.TemplateResponse(
            request=request,
            name="auth/register.html",
            context=ctx,
            status_code=status.HTTP_400_BAD_REQUEST
        )

    if password != confirm_password:
        ctx["error"] = "Passwords do not match. Please re-enter."
        return templates.TemplateResponse(
            request=request,
            name="auth/register.html",
            context=ctx,
            status_code=status.HTTP_400_BAD_REQUEST
        )

    existing = query_one("SELECT id FROM users WHERE email = ?", (email_clean,))
    if existing:
        ctx["error"] = "An account with this email address already exists. Please log in."
        return templates.TemplateResponse(
            request=request,
            name="auth/register.html",
            context=ctx,
            status_code=status.HTTP_409_CONFLICT
        )

    pw_hash = hash_password(password)
    user_id = execute_write("""
    INSERT INTO users (full_name, email, phone, password_hash, role, created_at, updated_at)
    VALUES (?, ?, ?, ?, 'customer', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    """, (full_name_clean, email_clean, phone_clean, pw_hash))

    session_id = create_session(user_id, "customer")
    target = return_to if return_to and return_to.startswith("/") else "/account"

    redirect_resp = RedirectResponse(target, status_code=status.HTTP_303_SEE_OTHER)
    redirect_resp.set_cookie(
        key=SESSION_COOKIE_NAME,
        value=session_id,
        max_age=SESSION_MAX_AGE,
        httponly=True,
        samesite="lax",
        secure=request.url.scheme == "https"
    )
    return redirect_resp

@router.get("/logout")
async def logout(request: Request):
    session_id = request.cookies.get(SESSION_COOKIE_NAME)
    if session_id:
        destroy_session(session_id)
    resp = RedirectResponse("/", status_code=status.HTTP_302_FOUND)
    resp.delete_cookie(SESSION_COOKIE_NAME)
    return resp

@router.get("/forgot-password", response_class=HTMLResponse)
async def forgot_password_page(request: Request):
    ctx = get_common_context(request)
    ctx["success_msg"] = None
    ctx["error"] = None
    return templates.TemplateResponse(
        request=request,
        name="auth/forgot_password.html",
        context=ctx
    )

@router.post("/forgot-password", response_class=HTMLResponse)
async def forgot_password_post(request: Request, email: str = Form(...), csrf_token: Optional[str] = Form(None)):
    """
    Production-safe forgot password flow:
    - Never leaks tokens or reset links into the HTML response.
    - Uses SHA-256 token hashing for database storage.
    - In development mode, logs the recovery link to the server console only.
    - Always shows a generic, privacy-preserving confirmation message.
    """
    await validate_csrf(request, csrf_token)
    ctx = get_common_context(request)
    email_clean = email.strip().lower()

    user = query_one("SELECT id, full_name, email FROM users WHERE email = ?", (email_clean,))
    if user:
        # Invalidate previous unused reset tokens for this user
        execute_query("UPDATE password_reset_tokens SET used = 1 WHERE user_id = ?", (user["id"],))

        # Generate cryptographically secure token and store its SHA-256 hash
        token = secrets.token_urlsafe(32)
        token_hashed = hash_token(token)
        expires_at = (datetime.utcnow() + timedelta(minutes=30)).strftime("%Y-%m-%d %H:%M:%S")

        execute_write("""
        INSERT INTO password_reset_tokens (user_id, token, expires_at, used)
        VALUES (?, ?, ?, 0)
        """, (user["id"], token_hashed, expires_at))

        reset_link = f"{APP_URL}/reset-password?token={token}"
        # Safe development-only console log (NEVER rendered on webpage)
        if DEBUG:
            print(f"\n[SECURITY LOG - DEV ONLY] Password Reset URL for {email_clean}: {reset_link}\n")
            logger.info(f"[DEV ONLY] Password Reset URL generated for {email_clean}")

    # Always show a uniform, safe response (no user enumeration, no token exposure)
    ctx["success_msg"] = "If an account exists with that email address, password reset instructions have been generated. Please check your email or contact the studio."
    return templates.TemplateResponse(
        request=request,
        name="auth/forgot_password.html",
        context=ctx
    )

@router.get("/reset-password", response_class=HTMLResponse)
async def reset_password_page(request: Request, token: str):
    ctx = get_common_context(request)
    ctx["token"] = token
    ctx["error"] = None
    ctx["success_msg"] = None

    token_hashed = hash_token(token)
    token_row = query_one("""
    SELECT t.id, t.user_id, t.expires_at, t.used, u.email 
    FROM password_reset_tokens t
    JOIN users u ON t.user_id = u.id
    WHERE (t.token = ? OR t.token = ?) AND t.used = 0 AND t.expires_at > CURRENT_TIMESTAMP
    """, (token_hashed, token))

    if not token_row:
        ctx["error"] = "Invalid or expired password reset link. Please request a new one."

    return templates.TemplateResponse(
        request=request,
        name="auth/reset_password.html",
        context=ctx
    )

@router.post("/reset-password", response_class=HTMLResponse)
async def reset_password_post(
    request: Request,
    token: str = Form(...),
    password: str = Form(...),
    confirm_password: str = Form(...),
    csrf_token: Optional[str] = Form(None)
):
    await validate_csrf(request, csrf_token)
    ctx = get_common_context(request)
    ctx["token"] = token
    ctx["error"] = None
    ctx["success_msg"] = None

    token_hashed = hash_token(token)
    token_row = query_one("""
    SELECT t.id, t.user_id, t.expires_at, t.used 
    FROM password_reset_tokens t
    WHERE (t.token = ? OR t.token = ?) AND t.used = 0 AND t.expires_at > CURRENT_TIMESTAMP
    """, (token_hashed, token))

    if not token_row:
        ctx["error"] = "This reset token is invalid or has expired."
        return templates.TemplateResponse(
            request=request,
            name="auth/reset_password.html",
            context=ctx
        )

    if len(password) < 6:
        ctx["error"] = "Password must be at least 6 characters."
        return templates.TemplateResponse(
            request=request,
            name="auth/reset_password.html",
            context=ctx
        )

    if password != confirm_password:
        ctx["error"] = "Passwords do not match."
        return templates.TemplateResponse(
            request=request,
            name="auth/reset_password.html",
            context=ctx
        )

    new_hash = hash_password(password)
    with get_db() as conn:
        conn.execute("UPDATE users SET password_hash = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", (new_hash, token_row["user_id"]))
        conn.execute("UPDATE password_reset_tokens SET used = 1 WHERE id = ?", (token_row["id"],))
    save_db_snapshot()

    # Invalidate all active sessions for security
    invalidate_user_sessions(token_row["user_id"])

    ctx["success_msg"] = "Your password has been successfully reset! You can now log in with your new password."
    return templates.TemplateResponse(
        request=request,
        name="auth/reset_password.html",
        context=ctx
    )

# JSON API for async frontend
@router.post("/api/auth/login")
async def api_auth_login(request: Request, response: Response):
    data = await request.json()
    await validate_csrf(request, data.get("csrf_token"))

    email = data.get("email", "").strip().lower()
    password = data.get("password", "")

    client_ip = request.client.host if request.client else "unknown"
    rate_limit_key = f"login:{client_ip}:{email}"
    check_login_rate_limit(rate_limit_key)

    user = query_one("SELECT * FROM users WHERE email = ?", (email,))
    if not user or not verify_password(password, user["password_hash"]):
        record_failed_login(rate_limit_key)
        raise HTTPException(status_code=401, detail="Invalid email or password.")

    clear_failed_logins(rate_limit_key)
    session_id = create_session(user["id"], user["role"])
    response.set_cookie(
        key=SESSION_COOKIE_NAME,
        value=session_id,
        max_age=SESSION_MAX_AGE,
        httponly=True,
        samesite="lax",
        secure=request.url.scheme == "https"
    )
    return {
        "success": True,
        "user": {
            "id": user["id"],
            "full_name": user["full_name"],
            "email": user["email"],
            "role": user["role"]
        },
        "session_id": session_id
    }

@router.get("/api/auth/me")
async def api_auth_me(request: Request):
    user = get_current_user(request)
    if not user:
        return {"authenticated": False, "user": None}
    return {
        "authenticated": True,
        "user": {
            "id": user["id"],
            "full_name": user["full_name"],
            "email": user["email"],
            "phone": user["phone"],
            "role": user["role"]
        }
    }
