
import sys
import os
import logging
from pathlib import Path

# Add project root to sys.path
BASE_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE_DIR))

# Ensure 9p DirectFileFinder is active
import app

from fastapi import FastAPI, Request, Response, status
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse

from app.templates_engine import Jinja2Templates
from app.database import init_db, query_one, get_db, save_db_snapshot
from app.routers import public, auth, oauth, booking, customer, admin
from app.routers.public import get_common_context
from app.config import CSRF_COOKIE_NAME
from app.csrf import generate_csrf_token
from app.security import hash_password

app = FastAPI(
    title="The Stylezone",
    description="Refined Grooming & Precision Haircuts in Dwarka Mor, Delhi",
    version="1.0.0"
)

# CSRF Cookie Middleware
@app.middleware("http")
async def csrf_cookie_middleware(request: Request, call_next):
    # Check if csrf cookie is present
    csrf_token = request.cookies.get(CSRF_COOKIE_NAME)
    token_to_set = None
    if not csrf_token:
        csrf_token = getattr(request.state, "csrf_token", None) or generate_csrf_token()
        token_to_set = csrf_token
        request.state.csrf_token = csrf_token

    response = await call_next(request)

    if token_to_set:
        response.set_cookie(
            key=CSRF_COOKIE_NAME,
            value=token_to_set,
            max_age=7 * 24 * 3600,
            httponly=False,  # Allow client-side JS to read token for AJAX requests
            samesite="lax",
            secure=request.url.scheme == "https"
        )
    return response

# Mount static files
static_dir = BASE_DIR / "app" / "static"
static_dir.mkdir(parents=True, exist_ok=True)
app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")

# Include Routers
app.include_router(public.router)
app.include_router(auth.router)
app.include_router(oauth.router)
app.include_router(booking.router)
app.include_router(customer.router)
app.include_router(admin.router)

templates = Jinja2Templates(directory=str(BASE_DIR / "app" / "templates"))

@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    ctx = get_common_context(request)
    return templates.TemplateResponse(
        request=request,
        name="404.html",
        context=ctx,
        status_code=404
    )

@app.exception_handler(500)
async def server_error_handler(request: Request, exc):
    ctx = get_common_context(request)
    return templates.TemplateResponse(
        request=request,
        name="500.html",
        context=ctx,
        status_code=500
    )

@app.on_event("startup")
async def on_startup():
    init_db()
    # Seed default services and settings if not yet present
    services_exist = query_one("SELECT id FROM services LIMIT 1")
    if not services_exist:
        from scripts.seed_demo import seed_database
        seed_database()

    # One-time admin bootstrap on application startup for deployment environments (e.g. Free Render)
    admin_exists = query_one("SELECT id FROM users WHERE role = 'admin' LIMIT 1")
    if admin_exists:
        logging.info("Admin already exists")
        print("Admin already exists")
    else:
        admin_email = os.getenv("ADMIN_EMAIL", "").strip()
        admin_password = os.getenv("ADMIN_PASSWORD", "")
        admin_name = os.getenv("ADMIN_NAME", "").strip()

        if admin_email and admin_password and admin_name:
            existing_user = query_one("SELECT id FROM users WHERE email = ?", (admin_email.lower(),))
            with get_db() as conn:
                if existing_user:
                    conn.execute(
                        """
                        UPDATE users
                        SET full_name = ?, password_hash = ?, role = 'admin', updated_at = CURRENT_TIMESTAMP
                        WHERE id = ?
                        """,
                        (admin_name, hash_password(admin_password), existing_user["id"])
                    )
                else:
                    conn.execute(
                        """
                        INSERT INTO users (full_name, email, password_hash, role, created_at, updated_at)
                        VALUES (?, ?, ?, 'admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
                        """,
                        (admin_name, admin_email.lower(), hash_password(admin_password))
                    )
            save_db_snapshot()
            logging.info("Admin bootstrap completed")
            print("Admin bootstrap completed")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
