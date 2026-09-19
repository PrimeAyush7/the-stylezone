import os
import secrets
from datetime import datetime, date, timedelta
from pathlib import Path
from typing import Optional, List
from fastapi import APIRouter, Request, Response, Form, UploadFile, File, HTTPException, status, Depends
from fastapi.responses import HTMLResponse, RedirectResponse, JSONResponse
from app.templates_engine import Jinja2Templates
from app.database import query_all, query_one, execute_write, execute_query, get_setting, set_setting, save_db_snapshot
from app.security import (
    require_admin, get_current_user, create_session, destroy_session, verify_password,
    check_login_rate_limit, record_failed_login, clear_failed_logins
)
from app.config import SESSION_COOKIE_NAME, SESSION_MAX_AGE, UPLOAD_DIR
from app.csrf import validate_csrf
from app.routers.public import get_common_context

templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))
router = APIRouter(prefix="/admin", tags=["Admin Panel"])

@router.get("/login", response_class=HTMLResponse)
async def admin_login_page(request: Request):
    user = get_current_user(request)
    if user and user["role"] == "admin":
        return RedirectResponse("/admin", status_code=status.HTTP_302_FOUND)
    ctx = get_common_context(request)
    ctx["error"] = None
    return templates.TemplateResponse(
        request=request,
        name="admin/login.html",
        context=ctx
    )

@router.post("/login", response_class=HTMLResponse)
async def admin_login_post(
    request: Request,
    response: Response,
    email: str = Form(...),
    password: str = Form(...),
    csrf_token: Optional[str] = Form(None)
):
    await validate_csrf(request, csrf_token)
    ctx = get_common_context(request)
    email_clean = email.strip().lower()

    client_ip = request.client.host if request.client else "unknown"
    rate_limit_key = f"admin_login:{client_ip}:{email_clean}"
    try:
        check_login_rate_limit(rate_limit_key, max_attempts=5, window_seconds=300)
    except HTTPException as he:
        ctx["error"] = he.detail
        return templates.TemplateResponse(
            request=request,
            name="admin/login.html",
            context=ctx,
            status_code=he.status_code
        )

    user = query_one("SELECT * FROM users WHERE email = ? AND role = 'admin'", (email_clean,))
    if not user or not verify_password(password, user["password_hash"]):
        record_failed_login(rate_limit_key)
        ctx["error"] = "Invalid administrator credentials."
        return templates.TemplateResponse(
            request=request,
            name="admin/login.html",
            context=ctx,
            status_code=status.HTTP_401_UNAUTHORIZED
        )

    clear_failed_logins(rate_limit_key)
    session_id = create_session(user["id"], "admin")
    resp = RedirectResponse("/admin", status_code=status.HTTP_303_SEE_OTHER)
    resp.set_cookie(
        key=SESSION_COOKIE_NAME,
        value=session_id,
        max_age=SESSION_MAX_AGE,
        httponly=True,
        samesite="lax",
        secure=request.url.scheme == "https"
    )
    return resp

@router.get("/logout")
async def admin_logout(request: Request):
    session_id = request.cookies.get(SESSION_COOKIE_NAME)
    if session_id:
        destroy_session(session_id)
    resp = RedirectResponse("/admin/login", status_code=status.HTTP_302_FOUND)
    resp.delete_cookie(SESSION_COOKIE_NAME)
    return resp

@router.get("", response_class=HTMLResponse)
async def admin_dashboard(request: Request):
    user = require_admin(request)
    ctx = get_common_context(request)
    today_str = date.today().strftime("%Y-%m-%d")

    # Metrics
    today_count = query_one("SELECT COUNT(*) as c FROM appointments WHERE appointment_date = ? AND status != 'cancelled'", (today_str,))["c"]
    pending_count = query_one("SELECT COUNT(*) as c FROM appointments WHERE status = 'pending'")["c"]
    confirmed_count = query_one("SELECT COUNT(*) as c FROM appointments WHERE status = 'confirmed'")["c"]
    completed_count = query_one("SELECT COUNT(*) as c FROM appointments WHERE status = 'completed'")["c"]
    cancelled_count = query_one("SELECT COUNT(*) as c FROM appointments WHERE status = 'cancelled'")["c"]
    total_customers = query_one("SELECT COUNT(*) as c FROM users WHERE role = 'customer'")["c"]
    
    rev_row = query_one("SELECT SUM(service_price) as rev FROM appointments WHERE status IN ('completed', 'confirmed')")
    total_revenue = rev_row["rev"] or 0.0

    ctx["metrics"] = {
        "today": today_count,
        "pending": pending_count,
        "confirmed": confirmed_count,
        "completed": completed_count,
        "cancelled": cancelled_count,
        "customers": total_customers,
        "revenue": total_revenue
    }

    ctx["today_appointments"] = query_all("""
        SELECT * FROM appointments 
        WHERE appointment_date = ?
        ORDER BY start_time ASC
    """, (today_str,))

    ctx["recent_appointments"] = query_all("""
        SELECT * FROM appointments 
        ORDER BY created_at DESC 
        LIMIT 8
    """)

    ctx["hours_configured"] = get_setting("hours_configured", "0") == "1"

    return templates.TemplateResponse(
        request=request,
        name="admin/dashboard.html",
        context=ctx
    )

@router.get("/appointments", response_class=HTMLResponse)
async def admin_appointments(
    request: Request,
    date_filter: Optional[str] = None,
    status_filter: Optional[str] = None,
    service_filter: Optional[int] = None,
    search: Optional[str] = None
):
    require_admin(request)
    ctx = get_common_context(request)

    sql = "SELECT * FROM appointments WHERE 1=1"
    params = []

    if date_filter:
        sql += " AND appointment_date = ?"
        params.append(date_filter)

    if status_filter:
        sql += " AND status = ?"
        params.append(status_filter)

    if service_filter:
        sql += " AND service_id = ?"
        params.append(service_filter)

    if search:
        s = f"%{search.strip()}%"
        sql += " AND (customer_name LIKE ? OR customer_email LIKE ? OR customer_phone LIKE ? OR booking_id LIKE ?)"
        params.extend([s, s, s, s])

    sql += " ORDER BY appointment_date DESC, start_time DESC LIMIT 100"

    ctx["appointments"] = query_all(sql, tuple(params))
    ctx["services"] = query_all("SELECT id, name FROM services ORDER BY name ASC")
    ctx["date_filter"] = date_filter or ""
    ctx["status_filter"] = status_filter or ""
    ctx["service_filter"] = service_filter
    ctx["search"] = search or ""

    return templates.TemplateResponse(
        request=request,
        name="admin/appointments.html",
        context=ctx
    )

@router.post("/appointments/{id}/status")
async def admin_update_appointment_status(
    request: Request,
    id: int,
    status: str = Form(...),
    csrf_token: Optional[str] = Form(None),
    cancellation_reason: Optional[str] = Form(None)
):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    if status not in ('pending', 'confirmed', 'completed', 'cancelled', 'no_show'):
        raise HTTPException(status_code=400, detail="Invalid appointment status.")

    cancelled_by = "admin" if status == "cancelled" else None
    execute_query("""
    UPDATE appointments 
    SET status = ?, cancellation_reason = COALESCE(?, cancellation_reason), cancelled_by = COALESCE(?, cancelled_by), updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
    """, (status, cancellation_reason, cancelled_by, id))

    return RedirectResponse(request.headers.get("referer", "/admin/appointments"), status_code=303)

@router.post("/appointments/create-manual")
async def admin_create_manual_appointment(
    request: Request,
    customer_name: str = Form(...),
    customer_email: str = Form(...),
    service_id: int = Form(...),
    appointment_date: str = Form(...),
    start_time: str = Form(...),
    csrf_token: Optional[str] = Form(None),
    customer_phone: Optional[str] = Form(None),
    notes: Optional[str] = Form(None)
):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    user = query_one("SELECT id FROM users WHERE email = ?", (customer_email.strip().lower(),))
    if user:
        cid = user["id"]
    else:
        cid = execute_write("""
        INSERT INTO users (full_name, email, phone, password_hash, role)
        VALUES (?, ?, ?, 'manual_no_pw', 'customer')
        """, (customer_name.strip(), customer_email.strip().lower(), customer_phone.strip() if customer_phone else ""))

    from app.availability import create_booking_atomic
    try:
        create_booking_atomic(
            customer_id=cid,
            customer_name=customer_name.strip(),
            customer_email=customer_email.strip().lower(),
            customer_phone=customer_phone,
            service_id=service_id,
            appointment_date=appointment_date,
            start_time=start_time,
            notes=notes
        )
    except Exception as e:
        return RedirectResponse(f"/admin/appointments?error={str(e)}", status_code=303)

    return RedirectResponse("/admin/appointments?success=Appointment+created+successfully", status_code=303)

@router.get("/calendar", response_class=HTMLResponse)
async def admin_calendar(request: Request, date_view: Optional[str] = None):
    require_admin(request)
    ctx = get_common_context(request)
    target_date = date_view or date.today().strftime("%Y-%m-%d")
    ctx["selected_date"] = target_date

    ctx["day_appointments"] = query_all("""
        SELECT * FROM appointments 
        WHERE appointment_date = ?
        ORDER BY start_time ASC
    """, (target_date,))

    ctx["day_blocks"] = query_all("SELECT * FROM blocked_slots WHERE date = ? ORDER BY start_time ASC", (target_date,))
    ctx["services"] = query_all("SELECT id, name FROM services WHERE is_active = 1")
    return templates.TemplateResponse(
        request=request,
        name="admin/calendar.html",
        context=ctx
    )

@router.post("/blocked-slots")
async def admin_add_blocked_slot(
    request: Request,
    date: str = Form(...),
    start_time: str = Form(...),
    end_time: str = Form(...),
    csrf_token: Optional[str] = Form(None),
    reason: Optional[str] = Form(None)
):
    admin_user = require_admin(request)
    await validate_csrf(request, csrf_token)

    execute_write("""
    INSERT INTO blocked_slots (date, start_time, end_time, reason, created_by)
    VALUES (?, ?, ?, ?, ?)
    """, (date, start_time, end_time, reason, admin_user["id"]))
    return RedirectResponse(request.headers.get("referer", "/admin/calendar"), status_code=303)

@router.post("/blocked-slots/{id}/delete")
async def admin_delete_blocked_slot(request: Request, id: int, csrf_token: Optional[str] = Form(None)):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    execute_query("DELETE FROM blocked_slots WHERE id = ?", (id,))
    return RedirectResponse(request.headers.get("referer", "/admin/calendar"), status_code=303)

@router.get("/services", response_class=HTMLResponse)
async def admin_services(request: Request):
    require_admin(request)
    ctx = get_common_context(request)
    ctx["services"] = query_all("SELECT * FROM services ORDER BY display_order ASC, price ASC")
    return templates.TemplateResponse(
        request=request,
        name="admin/services.html",
        context=ctx
    )

@router.post("/services/add")
async def admin_add_service(
    request: Request,
    name: str = Form(...),
    price: float = Form(...),
    duration_minutes: int = Form(...),
    csrf_token: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    is_active: int = Form(1)
):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    max_order = query_one("SELECT MAX(display_order) as m FROM services")["m"] or 0
    execute_write("""
    INSERT INTO services (name, price, duration_minutes, description, is_active, display_order)
    VALUES (?, ?, ?, ?, ?, ?)
    """, (name.strip(), price, duration_minutes, description, is_active, max_order + 1))
    return RedirectResponse("/admin/services?success=Service+added+successfully", status_code=303)

@router.post("/services/{id}/edit")
async def admin_edit_service(
    request: Request,
    id: int,
    name: str = Form(...),
    price: float = Form(...),
    duration_minutes: int = Form(...),
    csrf_token: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    is_active: int = Form(1)
):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    execute_query("""
    UPDATE services 
    SET name = ?, price = ?, duration_minutes = ?, description = ?, is_active = ?, updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
    """, (name.strip(), price, duration_minutes, description, is_active, id))
    return RedirectResponse("/admin/services?success=Service+updated+successfully", status_code=303)

@router.post("/services/{id}/toggle")
async def admin_toggle_service(request: Request, id: int, csrf_token: Optional[str] = Form(None)):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    service = query_one("SELECT is_active FROM services WHERE id = ?", (id,))
    if service:
        new_state = 0 if service["is_active"] == 1 else 1
        execute_query("UPDATE services SET is_active = ? WHERE id = ?", (new_state, id))
    return RedirectResponse("/admin/services", status_code=303)

@router.post("/services/{id}/delete")
async def admin_delete_service(request: Request, id: int, csrf_token: Optional[str] = Form(None)):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    has_bookings = query_one("SELECT id FROM appointments WHERE service_id = ? LIMIT 1", (id,))
    if has_bookings:
        execute_query("UPDATE services SET is_active = 0 WHERE id = ?", (id,))
        return RedirectResponse("/admin/services?notice=Service+has+existing+bookings+so+it+was+disabled+instead+of+deleted", status_code=303)
    else:
        execute_query("DELETE FROM services WHERE id = ?", (id,))
        return RedirectResponse("/admin/services?success=Service+deleted", status_code=303)

@router.get("/hours", response_class=HTMLResponse)
async def admin_hours(request: Request):
    require_admin(request)
    ctx = get_common_context(request)
    ctx["hours"] = query_all("SELECT * FROM business_hours ORDER BY day_of_week ASC")
    ctx["booking_enabled"] = get_setting("booking_enabled", "1") == "1"
    ctx["slot_duration_minutes"] = get_setting("slot_duration_minutes", "30")
    ctx["hours_configured"] = get_setting("hours_configured", "0") == "1"
    return templates.TemplateResponse(
        request=request,
        name="admin/hours.html",
        context=ctx
    )

@router.post("/hours")
async def admin_update_hours(request: Request):
    require_admin(request)
    form = await request.form()
    await validate_csrf(request, form.get("csrf_token"))

    booking_enabled = "1" if form.get("booking_enabled") == "on" else "0"
    slot_duration = form.get("slot_duration_minutes", "30")
    set_setting("booking_enabled", booking_enabled, "Master booking toggle")
    set_setting("slot_duration_minutes", slot_duration, "Default slot duration in minutes")
    
    # Mark hours as officially configured by the administrator
    set_setting("hours_configured", "1", "Hours configured by admin")

    for dow in range(7):
        is_open = 1 if form.get(f"is_open_{dow}") == "on" else 0
        open_time = form.get(f"open_time_{dow}", "").strip() or None
        close_time = form.get(f"close_time_{dow}", "").strip() or None
        has_break = 1 if form.get(f"has_break_{dow}") == "on" else 0
        break_start = form.get(f"break_start_{dow}", "").strip() or None
        break_end = form.get(f"break_end_{dow}", "").strip() or None

        execute_query("""
        UPDATE business_hours 
        SET is_open = ?, open_time = ?, close_time = ?, has_break = ?, break_start = ?, break_end = ?, updated_at = CURRENT_TIMESTAMP
        WHERE day_of_week = ?
        """, (is_open, open_time, close_time, has_break, break_start, break_end, dow))

    return RedirectResponse("/admin/hours?success=Business+hours+saved+successfully", status_code=303)

@router.get("/holidays", response_class=HTMLResponse)
async def admin_holidays(request: Request):
    require_admin(request)
    ctx = get_common_context(request)
    ctx["holidays"] = query_all("SELECT * FROM holidays ORDER BY date ASC")
    return templates.TemplateResponse(
        request=request,
        name="admin/holidays.html",
        context=ctx
    )

@router.post("/holidays/add")
async def admin_add_holiday(request: Request, date: str = Form(...), csrf_token: Optional[str] = Form(None), reason: Optional[str] = Form(None)):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    try:
        execute_write("INSERT INTO holidays (date, reason) VALUES (?, ?)", (date, reason.strip() if reason else "Holiday"))
    except Exception:
        return RedirectResponse("/admin/holidays?error=Holiday+for+this+date+already+exists", status_code=303)
    return RedirectResponse("/admin/holidays?success=Holiday+added+successfully", status_code=303)

@router.post("/holidays/{id}/delete")
async def admin_delete_holiday(request: Request, id: int, csrf_token: Optional[str] = Form(None)):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    execute_query("DELETE FROM holidays WHERE id = ?", (id,))
    return RedirectResponse("/admin/holidays?success=Holiday+removed", status_code=303)

@router.get("/gallery", response_class=HTMLResponse)
async def admin_gallery(request: Request):
    require_admin(request)
    ctx = get_common_context(request)
    ctx["gallery"] = query_all("SELECT * FROM gallery ORDER BY display_order ASC, id DESC")
    return templates.TemplateResponse(
        request=request,
        name="admin/gallery.html",
        context=ctx
    )

ALLOWED_IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif"}

def is_valid_image_magic(content: bytes) -> bool:
    """Validate image magic bytes to prevent malicious file uploads."""
    if len(content) < 8:
        return False
    # JPEG
    if content.startswith(b"\xff\xd8\xff"):
        return True
    # PNG
    if content.startswith(b"\x89PNG\r\n\x1a\n"):
        return True
    # GIF
    if content.startswith(b"GIF87a") or content.startswith(b"GIF89a"):
        return True
    # WEBP (RIFF....WEBP)
    if content.startswith(b"RIFF") and b"WEBP" in content[8:16]:
        return True
    return False

@router.post("/gallery/add")
async def admin_add_gallery(
    request: Request,
    title: str = Form(...),
    category: str = Form(...),
    csrf_token: Optional[str] = Form(None),
    image_url: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    image_file: Optional[UploadFile] = File(None)
):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    final_url = image_url.strip() if image_url else ""

    # Secure file upload validation
    if image_file and image_file.filename:
        file_ext = Path(image_file.filename).suffix.lower()
        if file_ext not in ALLOWED_IMAGE_EXTENSIONS:
            return RedirectResponse("/admin/gallery?error=Invalid+image+format.+Allowed:+JPG,+PNG,+WebP,+GIF", status_code=303)
        
        content = await image_file.read()
        # Enforce max 5MB file size
        if len(content) > 5 * 1024 * 1024:
            return RedirectResponse("/admin/gallery?error=Image+file+exceeds+maximum+5MB+limit", status_code=303)

        # Enforce magic bytes inspection
        if not is_valid_image_magic(content):
            return RedirectResponse("/admin/gallery?error=Corrupted+or+unsupported+image+content", status_code=303)

        saved_filename = f"{secrets.token_hex(16)}{file_ext}"
        file_dest = UPLOAD_DIR / saved_filename
        with open(file_dest, "wb") as f:
            f.write(content)
        final_url = f"/static/uploads/{saved_filename}"

    if not final_url:
        return RedirectResponse("/admin/gallery?error=Please+provide+an+image+URL+or+upload+a+valid+image+file", status_code=303)

    max_order = query_one("SELECT MAX(display_order) as m FROM gallery")["m"] or 0
    execute_write("""
    INSERT INTO gallery (title, category, image_url, description, is_active, display_order, is_placeholder)
    VALUES (?, ?, ?, ?, 1, ?, 0)
    """, (title.strip(), category.strip(), final_url, description, max_order + 1))

    return RedirectResponse("/admin/gallery?success=Image+added+to+gallery", status_code=303)

@router.post("/gallery/{id}/toggle")
async def admin_toggle_gallery(request: Request, id: int, csrf_token: Optional[str] = Form(None)):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    item = query_one("SELECT is_active FROM gallery WHERE id = ?", (id,))
    if item:
        new_val = 0 if item["is_active"] == 1 else 1
        execute_query("UPDATE gallery SET is_active = ? WHERE id = ?", (new_val, id))
    return RedirectResponse("/admin/gallery", status_code=303)

@router.post("/gallery/{id}/delete")
async def admin_delete_gallery(request: Request, id: int, csrf_token: Optional[str] = Form(None)):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    execute_query("DELETE FROM gallery WHERE id = ?", (id,))
    return RedirectResponse("/admin/gallery?success=Gallery+item+deleted", status_code=303)

@router.get("/content", response_class=HTMLResponse)
async def admin_content(request: Request):
    require_admin(request)
    ctx = get_common_context(request)
    return templates.TemplateResponse(
        request=request,
        name="admin/content.html",
        context=ctx
    )

@router.post("/content")
async def admin_save_content(request: Request):
    require_admin(request)
    form = await request.form()
    await validate_csrf(request, form.get("csrf_token"))

    editable_keys = [
        "business_name", "address", "phone_number", "whatsapp_number",
        "instagram_url", "google_maps_url", "hero_headline", "hero_description",
        "about_text", "why_choose_us_text", "footer_text", "cancellation_window_hours"
    ]

    for k in editable_keys:
        if k in form:
            set_setting(k, form[k].strip())

    return RedirectResponse("/admin/content?success=Website+content+updated+successfully", status_code=303)

@router.get("/reviews", response_class=HTMLResponse)
async def admin_reviews(request: Request):
    require_admin(request)
    ctx = get_common_context(request)
    ctx["reviews"] = query_all("SELECT * FROM reviews ORDER BY created_at DESC")
    return templates.TemplateResponse(
        request=request,
        name="admin/reviews.html",
        context=ctx
    )

@router.post("/reviews/add")
async def admin_add_review(
    request: Request,
    author_name: str = Form(...),
    rating: int = Form(5),
    content: str = Form(...),
    csrf_token: Optional[str] = Form(None),
    service_mentioned: Optional[str] = Form(None)
):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    execute_write("""
    INSERT INTO reviews (author_name, rating, content, service_mentioned, is_active, is_demo)
    VALUES (?, ?, ?, ?, 1, 0)
    """, (author_name.strip(), rating, content.strip(), service_mentioned.strip() if service_mentioned else None))
    return RedirectResponse("/admin/reviews?success=Review+added", status_code=303)

@router.post("/reviews/clear-demos")
async def admin_clear_demo_reviews(request: Request, csrf_token: Optional[str] = Form(None)):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    execute_query("DELETE FROM reviews WHERE is_demo = 1")
    return RedirectResponse("/admin/reviews?success=All+demo+reviews+have+been+removed", status_code=303)

@router.post("/reviews/{id}/toggle")
async def admin_toggle_review(request: Request, id: int, csrf_token: Optional[str] = Form(None)):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    rev = query_one("SELECT is_active FROM reviews WHERE id = ?", (id,))
    if rev:
        execute_query("UPDATE reviews SET is_active = ? WHERE id = ?", (0 if rev["is_active"] == 1 else 1, id))
    return RedirectResponse("/admin/reviews", status_code=303)

@router.post("/reviews/{id}/delete")
async def admin_delete_review(request: Request, id: int, csrf_token: Optional[str] = Form(None)):
    require_admin(request)
    await validate_csrf(request, csrf_token)

    execute_query("DELETE FROM reviews WHERE id = ?", (id,))
    return RedirectResponse("/admin/reviews?success=Review+deleted", status_code=303)

@router.get("/customers", response_class=HTMLResponse)
async def admin_customers(request: Request):
    require_admin(request)
    ctx = get_common_context(request)
    ctx["customers"] = query_all("""
        SELECT u.*, COUNT(a.id) as total_bookings, MAX(a.appointment_date) as last_booking_date
        FROM users u
        LEFT JOIN appointments a ON u.id = a.customer_id
        WHERE u.role = 'customer'
        GROUP BY u.id
        ORDER BY u.created_at DESC
    """)
    return templates.TemplateResponse(
        request=request,
        name="admin/customers.html",
        context=ctx
    )
