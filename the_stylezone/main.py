import sys
import os
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
from app.database import init_db, query_one
from app.routers import public, auth, oauth, booking, customer, admin
from app.routers.public import get_common_context
from app.config import CSRF_COOKIE_NAME
from app.csrf import generate_csrf_token

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
