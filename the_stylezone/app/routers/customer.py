from datetime import datetime, date
from fastapi import APIRouter, Request, HTTPException, status, Form, Depends
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
from pathlib import Path
from typing import Optional
from app.templates_engine import Jinja2Templates
from app.database import query_all, query_one, execute_query, get_setting, save_db_snapshot
from app.security import require_customer, get_current_user, hash_password, verify_password, invalidate_user_sessions
from app.csrf import validate_csrf
from app.routers.public import get_common_context

templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))
router = APIRouter(prefix="/account", tags=["Customer Account"])

@router.get("", response_class=HTMLResponse)
async def customer_dashboard(request: Request):
    user = get_current_user(request)
    if not user:
        return RedirectResponse("/login?return_to=/account", status_code=status.HTTP_302_FOUND)

    ctx = get_common_context(request)
    customer_id = user["id"]
    today_str = date.today().strftime("%Y-%m-%d")

    # Upcoming Appointments
    ctx["upcoming_appointments"] = query_all("""
        SELECT * FROM appointments 
        WHERE customer_id = ? AND status IN ('pending', 'confirmed') AND appointment_date >= ?
        ORDER BY appointment_date ASC, start_time ASC
    """, (customer_id, today_str))

    # Past Appointments
    ctx["past_appointments"] = query_all("""
        SELECT * FROM appointments 
        WHERE customer_id = ? AND (status IN ('completed', 'no_show') OR (appointment_date < ? AND status != 'cancelled'))
        ORDER BY appointment_date DESC, start_time DESC
    """, (customer_id, today_str))

    # Cancelled Appointments
    ctx["cancelled_appointments"] = query_all("""
        SELECT * FROM appointments 
        WHERE customer_id = ? AND status = 'cancelled'
        ORDER BY updated_at DESC
    """, (customer_id,))

    ctx["cancellation_window_hours"] = int(get_setting("cancellation_window_hours", "2"))
    return templates.TemplateResponse(
        request=request,
        name="customer/dashboard.html",
        context=ctx
    )

@router.post("/api/appointments/{booking_id}/cancel")
async def cancel_appointment_api(request: Request, booking_id: str):
    """Customer cancellation with CSRF & cancellation window verification."""
    user = require_customer(request)
    data = await request.json() if request.headers.get("content-type") == "application/json" else {}
    await validate_csrf(request, data.get("csrf_token"))

    reason = data.get("reason", "Cancelled by customer")

    appointment = query_one("""
    SELECT * FROM appointments 
    WHERE booking_id = ? AND customer_id = ?
    """, (booking_id, user["id"]))

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found or unauthorized.")

    if appointment["status"] == "cancelled":
        raise HTTPException(status_code=400, detail="This appointment is already cancelled.")

    if appointment["status"] == "completed":
        raise HTTPException(status_code=400, detail="Completed appointments cannot be cancelled.")

    min_notice_hours = int(get_setting("cancellation_window_hours", "2"))
    appt_dt_str = f"{appointment['appointment_date']} {appointment['start_time']}"
    appt_dt = datetime.strptime(appt_dt_str, "%Y-%m-%d %H:%M")
    
    hours_difference = (appt_dt - datetime.now()).total_seconds() / 3600.0
    if hours_difference < min_notice_hours:
        raise HTTPException(
            status_code=400, 
            detail=f"Cancellations require at least {min_notice_hours} hours advance notice. Please contact the shop directly."
        )

    execute_query("""
    UPDATE appointments 
    SET status = 'cancelled', cancellation_reason = ?, cancelled_by = 'customer', updated_at = CURRENT_TIMESTAMP
    WHERE id = ?
    """, (reason, appointment["id"]))

    return {
        "success": True,
        "message": "Your appointment has been successfully cancelled.",
        "booking_id": booking_id
    }

@router.post("/profile")
async def update_profile_post(
    request: Request,
    full_name: str = Form(...),
    csrf_token: Optional[str] = Form(None),
    phone: Optional[str] = Form(None)
):
    await validate_csrf(request, csrf_token)
    user = require_customer(request)
    full_name_clean = full_name.strip()
    phone_clean = phone.strip() if phone else ""

    if len(full_name_clean) < 2:
        return RedirectResponse("/account?error=Full+name+must+be+at+least+2+characters", status_code=status.HTTP_303_SEE_OTHER)

    execute_query("""
    UPDATE users SET full_name = ?, phone = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?
    """, (full_name_clean, phone_clean, user["id"]))

    return RedirectResponse("/account?success=Profile+updated+successfully", status_code=status.HTTP_303_SEE_OTHER)

@router.post("/change-password")
async def change_password_post(
    request: Request,
    current_password: str = Form(...),
    new_password: str = Form(...),
    confirm_password: str = Form(...),
    csrf_token: Optional[str] = Form(None)
):
    await validate_csrf(request, csrf_token)
    user = require_customer(request)
    db_user = query_one("SELECT password_hash FROM users WHERE id = ?", (user["id"],))

    if not verify_password(current_password, db_user["password_hash"]):
        return RedirectResponse("/account?error=Current+password+is+incorrect", status_code=status.HTTP_303_SEE_OTHER)

    if len(new_password) < 6:
        return RedirectResponse("/account?error=New+password+must+be+at+least+6+characters", status_code=status.HTTP_303_SEE_OTHER)

    if new_password != confirm_password:
        return RedirectResponse("/account?error=New+passwords+do+not+match", status_code=status.HTTP_303_SEE_OTHER)

    new_hash = hash_password(new_password)
    execute_query("UPDATE users SET password_hash = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?", (new_hash, user["id"]))

    return RedirectResponse("/account?success=Password+changed+successfully", status_code=status.HTTP_303_SEE_OTHER)
