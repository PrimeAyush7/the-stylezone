from fastapi import APIRouter, Request, HTTPException, status, Depends
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
from pathlib import Path
from typing import Optional
from app.templates_engine import Jinja2Templates
from app.database import query_all, query_one, get_setting
from app.security import get_current_user, create_session
from app.availability import calculate_availability, create_booking_atomic
from app.csrf import validate_csrf
from app.routers.public import get_common_context
from app.config import SESSION_COOKIE_NAME, SESSION_MAX_AGE

templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))
router = APIRouter(tags=["Booking"])

@router.get("/book", response_class=HTMLResponse)
async def booking_page(request: Request, service: Optional[int] = None):
    ctx = get_common_context(request)
    ctx["services"] = query_all("SELECT * FROM services WHERE is_active = 1 ORDER BY display_order ASC, price ASC")
    ctx["selected_service_id"] = service
    return templates.TemplateResponse(
        request=request,
        name="book.html",
        context=ctx
    )

@router.post("/api/bookings/create")
async def create_booking_api(request: Request):
    """
    Real appointment booking endpoint with CSRF verification, atomic database transactions,
    and double-booking prevention.
    """
    data = await request.json()
    await validate_csrf(request, data.get("csrf_token"))

    # Verify hours configured
    hours_configured = get_setting("hours_configured", "0") == "1"
    if not hours_configured:
        raise HTTPException(
            status_code=400,
            detail="Business operating hours have not yet been configured by the shop administration. Booking is disabled."
        )

    service_id = data.get("service_id")
    appointment_date = data.get("appointment_date")  # YYYY-MM-DD
    start_time = data.get("start_time")              # HH:MM
    notes = data.get("notes")

    if not service_id or not appointment_date or not start_time:
        raise HTTPException(status_code=400, detail="Missing required booking details (service, date, or time).")

    user = get_current_user(request)
    session_cookie_to_set = None

    if user:
        customer_id = user["id"]
        customer_name = user["full_name"]
        customer_email = user["email"]
        customer_phone = data.get("phone") or user["phone"]
    else:
        # Check guest details
        customer_name = data.get("name", "").strip()
        customer_email = data.get("email", "").strip().lower()
        customer_phone = data.get("phone", "").strip()

        if not customer_name or not customer_email:
            raise HTTPException(
                status_code=401, 
                detail="You must either be logged in or provide your full name and email to confirm your booking."
            )

        existing_user = query_one("SELECT id, full_name, phone FROM users WHERE email = ?", (customer_email,))
        if existing_user:
            customer_id = existing_user["id"]
            session_cookie_to_set = create_session(customer_id, "customer")
        else:
            from app.security import hash_password
            import secrets
            guest_pw = secrets.token_urlsafe(12)
            pw_hash = hash_password(guest_pw)
            from app.database import execute_write
            customer_id = execute_write("""
            INSERT INTO users (full_name, email, phone, password_hash, role, created_at, updated_at)
            VALUES (?, ?, ?, ?, 'customer', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
            """, (customer_name, customer_email, customer_phone, pw_hash))
            session_cookie_to_set = create_session(customer_id, "customer")

    try:
        booking_result = create_booking_atomic(
            customer_id=customer_id,
            customer_name=customer_name,
            customer_email=customer_email,
            customer_phone=customer_phone,
            service_id=int(service_id),
            appointment_date=appointment_date,
            start_time=start_time,
            notes=notes
        )
    except ValueError as ve:
        raise HTTPException(status_code=409, detail=str(ve))
    except Exception as e:
        raise HTTPException(status_code=500, detail="An error occurred while creating your appointment. Please try again.")

    response = JSONResponse(content={
        "success": True,
        "booking": booking_result,
        "redirect_url": f"/booking-confirmation/{booking_result['booking_id']}"
    })

    if session_cookie_to_set:
        response.set_cookie(
            key=SESSION_COOKIE_NAME,
            value=session_cookie_to_set,
            max_age=SESSION_MAX_AGE,
            httponly=True,
            samesite="lax",
            secure=request.url.scheme == "https"
        )

    return response

@router.get("/booking-confirmation/{booking_id}", response_class=HTMLResponse)
async def booking_confirmation_page(request: Request, booking_id: str):
    """
    PROTECTED BOOKING CONFIRMATION:
    Enforces authorization so customers can ONLY view their own bookings.
    Admins can view any booking.
    Unauthorized requests are rejected with 403 Forbidden (or 401 if unauthenticated).
    """
    user = get_current_user(request)
    if not user:
        return RedirectResponse(
            f"/login?return_to=/booking-confirmation/{booking_id}",
            status_code=status.HTTP_302_FOUND
        )

    ctx = get_common_context(request)
    appointment = query_one("""
    SELECT a.*, s.name as service_name, s.duration_minutes 
    FROM appointments a
    JOIN services s ON a.service_id = s.id
    WHERE a.booking_id = ?
    """, (booking_id,))

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found.")

    # Strict ownership / authorization check
    if user["role"] != "admin" and appointment["customer_id"] != user["id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden. You are not authorized to view another customer's appointment details."
        )

    ctx["appointment"] = appointment
    return templates.TemplateResponse(
        request=request,
        name="booking_confirmation.html",
        context=ctx
    )
