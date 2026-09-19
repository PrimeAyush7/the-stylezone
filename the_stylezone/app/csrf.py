import secrets
import hmac
from fastapi import Request, HTTPException, status
from app.config import CSRF_COOKIE_NAME

def generate_csrf_token() -> str:
    return secrets.token_urlsafe(32)

def get_csrf_token_from_request(request: Request) -> str:
    """Retrieve token from cookie or request state."""
    token = request.cookies.get(CSRF_COOKIE_NAME)
    if not token and hasattr(request.state, "csrf_token"):
        token = request.state.csrf_token
    return token or ""

async def validate_csrf(request: Request, submitted_token: str = None):
    """
    Validate CSRF token for state-changing requests.
    Checks cookie against submitted token (from form, header, or json).
    """
    expected_token = request.cookies.get(CSRF_COOKIE_NAME)
    if not expected_token:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="CSRF cookie missing or expired. Please refresh the page and try again."
        )

    token_to_verify = submitted_token

    if not token_to_verify:
        # Check header
        token_to_verify = request.headers.get("X-CSRF-Token") or request.headers.get("x-csrf-token")

    if not token_to_verify:
        # Try checking form if content type is form
        content_type = request.headers.get("content-type", "")
        if "application/x-www-form-urlencoded" in content_type or "multipart/form-data" in content_type:
            try:
                form = await request.form()
                token_to_verify = form.get("csrf_token")
            except Exception:
                pass
        elif "application/json" in content_type:
            try:
                body = await request.json()
                if isinstance(body, dict):
                    token_to_verify = body.get("csrf_token")
            except Exception:
                pass

    if not token_to_verify or not hmac.compare_digest(str(token_to_verify), str(expected_token)):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="CSRF validation failed. Form submission rejected."
        )
