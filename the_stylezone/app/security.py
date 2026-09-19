import os
import hmac
import hashlib
import secrets
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from fastapi import Request, HTTPException, status
from app.config import SECRET_KEY, SESSION_COOKIE_NAME, SESSION_MAX_AGE
from app.database import get_db, query_one, execute_write

# In-memory failed login attempts tracker for brute force protection
_failed_logins = {}  # key: ip_or_email, value: [timestamps]

def check_login_rate_limit(key: str, max_attempts: int = 5, window_seconds: int = 300):
    """Simple sliding window rate limiter for login protection."""
    now = datetime.utcnow()
    attempts = _failed_logins.get(key, [])
    # Filter attempts within window
    cutoff = now - timedelta(seconds=window_seconds)
    valid_attempts = [t for t in attempts if t > cutoff]
    _failed_logins[key] = valid_attempts
    
    if len(valid_attempts) >= max_attempts:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many failed login attempts. Please wait 5 minutes before trying again."
        )

def record_failed_login(key: str):
    now = datetime.utcnow()
    attempts = _failed_logins.get(key, [])
    attempts.append(now)
    _failed_logins[key] = attempts

def clear_failed_logins(key: str):
    _failed_logins.pop(key, None)

def hash_password(password: str) -> str:
    """Hash password securely using PBKDF2-HMAC-SHA256 with 260,000 rounds and random salt."""
    salt = secrets.token_bytes(16)
    key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 260000)
    return f"pbkdf2:sha256:260000${salt.hex()}${key.hex()}"

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password in constant time."""
    try:
        parts = hashed_password.split("$")
        if len(parts) != 3:
            return False
        algo_info, salt_hex, key_hex = parts
        salt = bytes.fromhex(salt_hex)
        expected_key = bytes.fromhex(key_hex)
        algo, subalgo, iterations = algo_info.split(":")
        iterations = int(iterations)
        actual_key = hashlib.pbkdf2_hmac(subalgo, plain_password.encode("utf-8"), salt, iterations)
        return hmac.compare_digest(actual_key, expected_key)
    except Exception:
        return False

def hash_token(token: str) -> str:
    """Hash a sensitive token (like password reset token) before database storage."""
    return hashlib.sha256(token.encode("utf-8")).hexdigest()

def create_session(user_id: int, role: str) -> str:
    session_id = secrets.token_urlsafe(32)
    expires_at = (datetime.utcnow() + timedelta(seconds=SESSION_MAX_AGE)).strftime("%Y-%m-%d %H:%M:%S")
    with get_db() as conn:
        conn.execute("""
        INSERT INTO sessions (session_id, user_id, role, expires_at)
        VALUES (?, ?, ?, ?)
        """, (session_id, user_id, role, expires_at))
    return session_id

def destroy_session(session_id: str):
    if session_id:
        with get_db() as conn:
            conn.execute("DELETE FROM sessions WHERE session_id = ?", (session_id,))

def invalidate_user_sessions(user_id: int):
    """Revoke all active sessions for a user upon password change or reset."""
    with get_db() as conn:
        conn.execute("DELETE FROM sessions WHERE user_id = ?", (user_id,))

def get_current_user(request: Request) -> Optional[Dict[str, Any]]:
    session_id = request.cookies.get(SESSION_COOKIE_NAME)
    if not session_id:
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            session_id = auth_header[7:].strip()
            
    if not session_id:
        return None

    sql = """
    SELECT u.id, u.full_name, u.email, u.phone, u.role, u.oauth_provider, s.expires_at, s.session_id
    FROM sessions s
    JOIN users u ON s.user_id = u.id
    WHERE s.session_id = ? AND s.expires_at > CURRENT_TIMESTAMP
    """
    user = query_one(sql, (session_id,))
    return user

def require_customer(request: Request) -> Dict[str, Any]:
    user = get_current_user(request)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required. Please log in to continue."
        )
    return user

def require_admin(request: Request) -> Dict[str, Any]:
    user = get_current_user(request)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Admin authentication required. Please log in to continue."
        )
    if user.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden. Administrator access required."
        )
    return user
