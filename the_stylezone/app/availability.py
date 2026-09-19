import secrets
from datetime import datetime, timedelta, date
from typing import List, Dict, Any, Optional
import sqlite3
from app.database import get_db, query_one, query_all, get_setting, save_db_snapshot

def parse_time_to_minutes(time_str: str) -> int:
    parts = time_str.strip().split(":")
    return int(parts[0]) * 60 + int(parts[1])

def minutes_to_time(minutes: int) -> str:
    hours = minutes // 60
    mins = minutes % 60
    return f"{hours:02d}:{mins:02d}"

def calculate_availability(target_date_str: str, service_id: Optional[int] = None) -> Dict[str, Any]:
    try:
        target_date = datetime.strptime(target_date_str, "%Y-%m-%d").date()
    except ValueError:
        return {"error": "Invalid date format. Expected YYYY-MM-DD", "available": False, "slots": []}

    today = date.today()
    now = datetime.now()

    # Master switch
    booking_enabled = get_setting("booking_enabled", "1") == "1"
    if not booking_enabled:
        return {
            "date": target_date_str,
            "available": False,
            "message": "Online booking is temporarily paused by administration. Please check back soon.",
            "is_open": False,
            "slots": []
        }

    # CRITICAL: Check if business hours have been configured by the admin!
    hours_configured = get_setting("hours_configured", "0") == "1"
    if not hours_configured:
        return {
            "date": target_date_str,
            "available": False,
            "is_configured": False,
            "message": "Business operating hours have not yet been configured by shop administration. Online booking is unavailable.",
            "is_open": False,
            "slots": []
        }

    # Prevent past dates
    if target_date < today:
        return {
            "date": target_date_str,
            "available": False,
            "message": "Cannot book appointments for past dates.",
            "is_open": False,
            "slots": []
        }

    if target_date > today + timedelta(days=60):
        return {
            "date": target_date_str,
            "available": False,
            "message": "Appointments can only be booked up to 60 days in advance.",
            "is_open": False,
            "slots": []
        }

    # Holidays
    holiday = query_one("SELECT reason FROM holidays WHERE date = ?", (target_date_str,))
    if holiday:
        return {
            "date": target_date_str,
            "available": False,
            "is_holiday": True,
            "message": f"Closed for holiday: {holiday['reason'] or 'Special Holiday'}",
            "slots": []
        }

    # Day of week - retrieve configured business hours from database
    dow = target_date.weekday()
    hours = query_one("SELECT * FROM business_hours WHERE day_of_week = ?", (dow,))
    
    # Weekly Off is respected only when the corresponding database setting is enabled (is_open == 0)
    if not hours or hours["is_open"] == 0:
        day_name = hours["day_name"] if hours else "This day"
        return {
            "date": target_date_str,
            "available": False,
            "is_open": False,
            "message": f"The Stylezone is closed on {day_name}s (Weekly Off).",
            "slots": []
        }

    open_time_str = hours["open_time"] or "08:00"
    close_time_str = hours["close_time"] or "22:00"
    open_min = parse_time_to_minutes(open_time_str)
    close_min = parse_time_to_minutes(close_time_str)

    slot_duration = 30
    if service_id:
        srv = query_one("SELECT duration_minutes FROM services WHERE id = ? AND is_active = 1", (service_id,))
        if srv and srv["duration_minutes"] > 0:
            slot_duration = srv["duration_minutes"]
    else:
        try:
            slot_duration = int(get_setting("slot_duration_minutes", "30"))
        except ValueError:
            slot_duration = 30

    has_break = hours["has_break"] == 1
    break_start_min = parse_time_to_minutes(hours["break_start"]) if has_break and hours["break_start"] else -1
    break_end_min = parse_time_to_minutes(hours["break_end"]) if has_break and hours["break_end"] else -1

    active_appointments = query_all("""
        SELECT start_time, end_time FROM appointments 
        WHERE appointment_date = ? AND status != 'cancelled'
    """, (target_date_str,))

    blocked = query_all("""
        SELECT start_time, end_time, reason FROM blocked_slots 
        WHERE date = ?
    """, (target_date_str,))

    busy_intervals = []
    for appt in active_appointments:
        s = parse_time_to_minutes(appt["start_time"])
        e = parse_time_to_minutes(appt["end_time"])
        busy_intervals.append((s, e, "Already Booked"))

    for blk in blocked:
        s = parse_time_to_minutes(blk["start_time"])
        e = parse_time_to_minutes(blk["end_time"])
        busy_intervals.append((s, e, blk["reason"] or "Blocked by Admin"))

    slots = []
    current_min = open_min

    while current_min + slot_duration <= close_min:
        slot_start_time = minutes_to_time(current_min)
        slot_end_min = current_min + slot_duration
        slot_end_time = minutes_to_time(slot_end_min)

        is_available = True
        unavailable_reason = None

        if target_date == today:
            cutoff_min = now.hour * 60 + now.minute + 15
            if current_min < cutoff_min:
                is_available = False
                unavailable_reason = "Past slot"

        if is_available and has_break:
            if not (slot_end_min <= break_start_min or current_min >= break_end_min):
                is_available = False
                unavailable_reason = "Shop Break"

        if is_available:
            for b_start, b_end, reason in busy_intervals:
                if max(current_min, b_start) < min(slot_end_min, b_end):
                    is_available = False
                    unavailable_reason = reason
                    break

        slots.append({
            "time": slot_start_time,
            "end_time": slot_end_time,
            "available": is_available,
            "reason": unavailable_reason
        })

        current_min += 30

    available_count = sum(1 for s in slots if s["available"])

    return {
        "date": target_date_str,
        "available": available_count > 0,
        "is_configured": True,
        "day_name": hours["day_name"],
        "open_time": open_time_str,
        "close_time": close_time_str,
        "slot_duration": slot_duration,
        "total_slots": len(slots),
        "available_count": available_count,
        "slots": slots
    }

def create_booking_atomic(
    customer_id: int,
    customer_name: str,
    customer_email: str,
    customer_phone: Optional[str],
    service_id: int,
    appointment_date: str,
    start_time: str,
    notes: Optional[str] = None
) -> Dict[str, Any]:
    """Atomic booking with database transaction and double-booking prevention."""
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("BEGIN IMMEDIATE;")
        try:
            # Check if hours configured
            cursor.execute("SELECT value FROM business_settings WHERE key = 'hours_configured'")
            h_row = cursor.fetchone()
            if not h_row or h_row["value"] != "1":
                raise ValueError("Shop operating hours have not yet been configured by administration.")

            cursor.execute("SELECT name, price, duration_minutes, is_active FROM services WHERE id = ?", (service_id,))
            service = cursor.fetchone()
            if not service:
                raise ValueError("Selected service was not found.")
            if service["is_active"] != 1:
                raise ValueError("Selected service is currently inactive.")

            service_name = service["name"]
            service_price = float(service["price"])
            duration_minutes = service["duration_minutes"]

            start_min = parse_time_to_minutes(start_time)
            end_min = start_min + duration_minutes
            end_time = minutes_to_time(end_min)

            # Holiday check
            cursor.execute("SELECT reason FROM holidays WHERE date = ?", (appointment_date,))
            if cursor.fetchone():
                raise ValueError(f"The shop is closed for a holiday on {appointment_date}.")

            # Hours check
            target_date = datetime.strptime(appointment_date, "%Y-%m-%d").date()
            dow = target_date.weekday()
            cursor.execute("SELECT * FROM business_hours WHERE day_of_week = ?", (dow,))
            hours = cursor.fetchone()
            if not hours or hours["is_open"] == 0:
                day_name = hours["day_name"] if hours else "This day"
                raise ValueError(f"The shop is closed on {day_name}s (Weekly Off).")

            open_time_str = hours["open_time"] or "08:00"
            close_time_str = hours["close_time"] or "22:00"
            open_min = parse_time_to_minutes(open_time_str)
            close_min = parse_time_to_minutes(close_time_str)
            if start_min < open_min or end_min > close_min:
                raise ValueError(f"Selected time {start_time}-{end_time} is outside operating hours ({open_time_str}-{close_time_str}).")

            if hours["has_break"] == 1 and hours["break_start"] and hours["break_end"]:
                b_start = parse_time_to_minutes(hours["break_start"])
                b_end = parse_time_to_minutes(hours["break_end"])
                if max(start_min, b_start) < min(end_min, b_end):
                    raise ValueError(f"Selected time overlaps with shop break ({hours['break_start']}-{hours['break_end']}).")

            # Check blocked slots
            cursor.execute("""
                SELECT id FROM blocked_slots 
                WHERE date = ? AND (
                    (start_time <= ? AND end_time > ?) OR
                    (start_time < ? AND end_time >= ?) OR
                    (start_time >= ? AND end_time <= ?)
                )
            """, (appointment_date, start_time, start_time, end_time, end_time, start_time, end_time))
            if cursor.fetchone():
                raise ValueError("This time slot has been blocked by administration.")

            # Check conflict with existing active appointment
            cursor.execute("""
                SELECT id, booking_id FROM appointments 
                WHERE appointment_date = ? 
                  AND status != 'cancelled'
                  AND (
                      (start_time <= ? AND end_time > ?) OR
                      (start_time < ? AND end_time >= ?) OR
                      (start_time >= ? AND end_time <= ?)
                  )
            """, (appointment_date, start_time, start_time, end_time, end_time, start_time, end_time))
            conflict = cursor.fetchone()
            if conflict:
                raise ValueError("This slot was just booked by another customer. Please choose an alternative slot.")

            # Unique Booking ID
            date_clean = appointment_date.replace("-", "")
            rand_suffix = secrets.token_hex(2).upper()
            booking_id = f"SZ-{date_clean}-{rand_suffix}"

            cursor.execute("""
            INSERT INTO appointments (
                booking_id, customer_id, customer_name, customer_email, customer_phone,
                service_id, service_name, service_price, appointment_date, start_time, end_time,
                status, notes, payment_status, payment_method, created_at, updated_at
            ) VALUES (
                ?, ?, ?, ?, ?,
                ?, ?, ?, ?, ?, ?,
                'pending', ?, 'unpaid', 'cash_at_counter', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
            )
            """, (
                booking_id, customer_id, customer_name, customer_email, customer_phone,
                service_id, service_name, service_price, appointment_date, start_time, end_time,
                notes
            ))

            new_id = cursor.lastrowid
            cursor.execute("COMMIT;")

            save_db_snapshot()

            return {
                "success": True,
                "appointment_id": new_id,
                "booking_id": booking_id,
                "service_name": service_name,
                "service_price": service_price,
                "appointment_date": appointment_date,
                "start_time": start_time,
                "end_time": end_time,
                "status": "pending"
            }

        except sqlite3.IntegrityError:
            cursor.execute("ROLLBACK;")
            raise ValueError("A conflict occurred for this exact slot. Please choose another time.")
        except Exception as e:
            cursor.execute("ROLLBACK;")
            raise e
