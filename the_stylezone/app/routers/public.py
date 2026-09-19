from fastapi import APIRouter, Request, Depends, HTTPException, Query
from fastapi.responses import HTMLResponse, JSONResponse
from app.templates_engine import Jinja2Templates
from app.database import query_all, query_one, get_setting
from app.security import get_current_user
from app.availability import calculate_availability
from app.csrf import get_csrf_token_from_request, generate_csrf_token
from app.config import CSRF_COOKIE_NAME
from pathlib import Path
from typing import Optional

templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))
router = APIRouter(tags=["Public"])

def get_common_context(request: Request) -> dict:
    user = get_current_user(request)
    settings_rows = query_all("SELECT key, value FROM business_settings")
    settings = {r["key"]: r["value"] for r in settings_rows}
    
    # Defaults
    settings.setdefault("business_name", "The Stylezone")
    settings.setdefault("address", "Street no 32, Vipin Garden Extension, Dwarka Mor, Delhi")
    settings.setdefault("hero_headline", "Refined Grooming For The Modern Gentleman")
    settings.setdefault("hero_description", "Precision haircuts, master beard sculpting, and revitalizing skin treatments in Dwarka Mor, Delhi.")
    settings.setdefault("about_text", "The Stylezone brings refined grooming and sharp craftsmanship to Dwarka Mor, Delhi. Dedicated to delivering consistent quality for every client.")
    settings.setdefault("why_choose_us_text", "Focused styling expertise, comfortable ambiance, and dedicated attention tailored to your personal aesthetic.")
    settings.setdefault("footer_text", "© 2026 The Stylezone. All rights reserved.")
    settings.setdefault("booking_enabled", "1")
    settings.setdefault("hours_configured", "0")

    # CSRF Token
    csrf_token = request.cookies.get(CSRF_COOKIE_NAME)
    if not csrf_token:
        csrf_token = getattr(request.state, "csrf_token", None) or generate_csrf_token()
        request.state.csrf_token = csrf_token
    
    return {
        "request": request,
        "user": user,
        "settings": settings,
        "csrf_token": csrf_token,
        "hours_configured": settings.get("hours_configured") == "1"
    }

@router.get("/", response_class=HTMLResponse)
async def home_page(request: Request):
    ctx = get_common_context(request)
    ctx["services"] = query_all("SELECT * FROM services WHERE is_active = 1 ORDER BY display_order ASC, price ASC")
    ctx["gallery"] = query_all("SELECT * FROM gallery WHERE is_active = 1 ORDER BY display_order ASC LIMIT 6")
    ctx["reviews"] = query_all("SELECT * FROM reviews WHERE is_active = 1 ORDER BY created_at DESC LIMIT 3")
    ctx["hours"] = query_all("SELECT * FROM business_hours ORDER BY day_of_week ASC")
    return templates.TemplateResponse(
        request=request,
        name="index.html",
        context=ctx
    )

@router.get("/services", response_class=HTMLResponse)
async def services_page(request: Request):
    ctx = get_common_context(request)
    ctx["services"] = query_all("SELECT * FROM services WHERE is_active = 1 ORDER BY display_order ASC, price ASC")
    return templates.TemplateResponse(
        request=request,
        name="services.html",
        context=ctx
    )

@router.get("/lookbook", response_class=HTMLResponse)
async def lookbook_page(request: Request):
    ctx = get_common_context(request)
    ctx["gallery"] = query_all("SELECT * FROM gallery WHERE is_active = 1 ORDER BY display_order ASC, id DESC")
    categories = sorted(list({item["category"] for item in ctx["gallery"] if item["category"]}))
    ctx["categories"] = categories
    return templates.TemplateResponse(
        request=request,
        name="lookbook.html",
        context=ctx
    )

@router.get("/about", response_class=HTMLResponse)
async def about_page(request: Request):
    ctx = get_common_context(request)
    return templates.TemplateResponse(
        request=request,
        name="about.html",
        context=ctx
    )

@router.get("/contact", response_class=HTMLResponse)
async def contact_page(request: Request):
    ctx = get_common_context(request)
    ctx["hours"] = query_all("SELECT * FROM business_hours ORDER BY day_of_week ASC")
    return templates.TemplateResponse(
        request=request,
        name="contact.html",
        context=ctx
    )

# API Endpoints
@router.get("/api/public/info")
async def api_public_info():
    settings_rows = query_all("SELECT key, value FROM business_settings")
    settings = {r["key"]: r["value"] for r in settings_rows}
    services = query_all("SELECT id, name, price, duration_minutes, description FROM services WHERE is_active = 1 ORDER BY display_order ASC")
    hours = query_all("SELECT day_of_week, day_name, is_open, open_time, close_time FROM business_hours ORDER BY day_of_week ASC")
    
    return {
        "business": settings,
        "services": services,
        "hours": hours,
        "hours_configured": settings.get("hours_configured") == "1"
    }

@router.get("/api/public/services")
async def api_public_services():
    services = query_all("SELECT * FROM services WHERE is_active = 1 ORDER BY display_order ASC, price ASC")
    return {"services": services}

@router.get("/api/public/availability")
async def api_public_availability(date: str = Query(..., pattern=r"^\d{4}-\d{2}-\d{2}$"), service_id: Optional[int] = None):
    res = calculate_availability(date, service_id)
    return res
