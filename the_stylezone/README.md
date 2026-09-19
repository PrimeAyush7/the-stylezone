# The Stylezone -- Full-Stack Luxury Barber & Grooming Web Application

> **Official Business Name:** The Stylezone  
> **Location:** Street no 32, Vipin Garden Extension, Dwarka Mor, Delhi  
> **Brand Identity:** Modern, Masculine, Premium Black & Gold Luxury Grooming  

---

## 1. What the Project Is

**The Stylezone** is a complete, production-grade web application built specifically for a premium local barbershop and men's grooming business in Dwarka Mor, Delhi.

Unlike a static marketing page or a visual frontend demo, this application is a **true full-stack software system** with:
- A public luxury client-facing website with dark/light mode toggle and mobile-first responsiveness.
- A dynamic, database-driven service menu and grooming lookbook.
- A **real appointment booking engine** with server-side availability calculation, shop hours, holidays, and break intervals.
- **Strict database-level double-booking protection** to prevent scheduling conflicts.
- **Secure customer authentication** (email/password with PBKDF2 hashing, secure HTTP-only session cookies, profile management, and password recovery).
- A **dedicated Customer Portal** to view upcoming, past, and cancelled appointments with one-click self-cancellation respecting business policy.
- A **non-technical Admin Dashboard** allowing a shop owner to manage appointments, calendar schedules, blocked time windows, services, pricing, business hours, holidays, website copy, gallery imagery, and customer records without ever touching code.

---

## 2. Tech Stack

- **Backend / API Framework:** Python 3.11 + FastAPI (Async high-performance RESTful API with Pydantic validation and OpenAPI documentation at `/docs`).
- **Web Server:** Uvicorn (ASGI lightning-fast web server).
- **Database:** SQLite 3 with ACID transactions, atomic writes, and snapshot synchronization (with a 1:1 migration path to PostgreSQL/MySQL via standard SQL).
- **Authentication & Security:** PBKDF2-HMAC-SHA256 (260,000 iterations), per-user salts, constant-time verification, cryptographic session tokens stored in secure `HTTP-only` cookies, server-side role validation (`customer` vs `admin`).
- **Frontend / Templating:** Jinja2 server-side rendering + Modern Vanilla ES6 JavaScript (zero heavy client-side bundle overhead).
- **Styling System:** Handcrafted Black & Gold Luxury Design System (CSS variables, glassmorphism, responsive grid & flexbox, accessible high-contrast light and dark themes).

---

## 3. Folder Structure

```
the-stylezone/
├── app/
│   ├── __init__.py            # Direct file loader & package setup
│   ├── config.py              # Environment variables & constants
│   ├── database.py            # SQLite connection, schema, transactions & snapshots
│   ├── security.py            # Password hashing, sessions, & role authorization
│   ├── availability.py        # Real slot calculation & atomic booking engine
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── public.py          # Public pages (Home, Services, Lookbook, About, Contact)
│   │   ├── auth.py            # Login, Registration, Logout, Password Recovery
│   │   ├── oauth.py           # Google & Facebook OAuth integration endpoints
│   │   ├── booking.py         # 5-Step interactive booking wizard & booking API
│   │   ├── customer.py        # Customer dashboard & appointment management
│   │   └── admin.py           # Comprehensive non-technical admin dashboard
│   ├── static/
│   │   ├── css/
│   │   │   └── style.css      # Luxury Black & Gold theme (Dark + Light mode)
│   │   ├── js/
│   │   │   ├── main.js        # Theme toggle engine & mobile menu
│   │   │   ├── booking.js     # Step-by-step booking client logic
│   │   │   ├── customer.js    # Customer cancellation modal & profile forms
│   │   │   └── admin.js       # Admin modal managers & date utilities
│   │   └── uploads/           # Admin-uploaded images
│   └── templates/             # Jinja2 HTML templates
│       ├── base.html          # Global header, navbar, footer, theme engine
│       ├── index.html         # Homepage (Hero, Services, Lookbook, About, Map)
│       ├── services.html      # Services catalog with instant booking triggers
│       ├── lookbook.html      # Categorized male grooming hairstyles lookbook
│       ├── about.html         # Brand craftsmanship and values
│       ├── contact.html       # Location, opening hours, contact details
│       ├── book.html          # Interactive 5-step booking wizard
│       ├── booking_confirmation.html # Booking receipt card with unique ID
│       ├── 404.html / 500.html # Branded error pages
│       ├── auth/              # Login, register, forgot/reset password templates
│       ├── customer/          # Customer dashboard & appointments view
│       └── admin/             # Complete suite of admin management screens
├── data/
│   ├── the_stylezone.db       # Active SQLite database
│   └── the_stylezone.sql      # Database snapshot (schema + seeded data)
├── scripts/
│   ├── seed_demo.py           # Database initial seeder
│   ├── create_admin.py        # Admin account creation / password reset CLI
│   └── test_app.py            # Automated end-to-end test suite
├── main.py                    # Application factory
├── run.py                     # Local development runner
├── .env.example               # Environment variables template
├── .env                       # Local environment file
└── README.md                  # Complete documentation
```

---

## 4. Requirements

- **Python:** Python 3.9+ (Python 3.11 recommended)
- **Pip:** Standard Python package manager
- **Web Browser:** Any modern browser (Chrome, Safari, Edge, Firefox)

---

## 5. Installation

1. **Clone or Download the Repository:**
   ```bash
   git clone https://github.com/your-username/the-stylezone.git
   cd the-stylezone
   ```

2. **Create a Virtual Environment (Recommended):**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Dependencies:**
   ```bash
   pip install fastapi uvicorn jinja2 python-multipart python-dotenv cryptography
   ```

---

## 6. Database Setup

The application automatically creates and verifies all database tables on startup.

To seed the confirmed business services, initial lookbook styles, and default operating hours, run:
```bash
python3 scripts/seed_demo.py
```

This populates the database with:
- **Haircut** — ₹100 (30 mins)
- **Beard** — ₹70 (20 mins)
- **Haircut + Beard** — ₹150 (45 mins)
- **Facial** — ₹300 (45 mins)
- **D-Tan** — ₹300 (45 mins)
- Business location: `Street no 32, Vipin Garden Extension, Dwarka Mor, Delhi`
- Default schedule: Monday through Sunday, 09:00 to 21:00.

---

## 7. Environment Variables

Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

| Variable | Description | Default |
|---|---|---|
| `SECRET_KEY` | Secret used for session security | Secure random string |
| `DATABASE_PATH` | Path to SQLite database file | `/tmp/the_stylezone.db` |
| `APP_URL` | Public base URL of your website | `http://localhost:8000` |
| `GOOGLE_CLIENT_ID` | Optional: Google OAuth 2.0 Client ID | (Leave empty until configured) |
| `GOOGLE_CLIENT_SECRET` | Optional: Google OAuth 2.0 Client Secret | (Leave empty until configured) |
| `FACEBOOK_CLIENT_ID` | Optional: Facebook App ID | (Leave empty until configured) |
| `FACEBOOK_CLIENT_SECRET` | Optional: Facebook App Secret | (Leave empty until configured) |

---

## 8. How to Run Locally

Start the local server with:
```bash
python3 run.py
```

Or using Uvicorn directly:
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

Open your browser at:
**`http://localhost:8000`**

To run the automated verification suite:
```bash
python3 scripts/test_app.py
```

---

## 9. How to Create Admin Account

To create your primary administrator account or reset the admin password, run:
```bash
python3 scripts/create_admin.py --email your-admin@example.com --password "YourSecretPassword123!" --name "Shop Owner"
```

Login at: **`http://localhost:8000/admin/login`**

---

## 10. How Customer Registration Works

1. Customer visits `/register` or clicks **"Create Account"**.
2. They input their **Full Name**, **Email**, **Phone (Optional)**, and **Password**.
3. Passwords are salted and hashed using PBKDF2-HMAC-SHA256 (never stored in plaintext).
4. On registration, a secure session token is set as an `HTTP-only` cookie (`stylezone_session`).
5. The customer is redirected to their **Customer Dashboard** (`/account`).
6. If a customer books as a guest, the system automatically creates their account and links their appointment.

---

## 11. How Booking Works

The booking system follows an intuitive 5-step flow:
1. **Step 1 — Choose Service:** Select from database services (Haircut ₹100, Beard ₹70, etc.).
2. **Step 2 — Choose Date:** Pick a date up to 60 days ahead (past dates disabled).
3. **Step 3 — Available Time:** The backend dynamically checks the day's opening hours, holidays, lunch breaks, and existing appointments, returning only truly available slots as interactive buttons.
4. **Step 4 — Contact Details:** Auto-fills if logged in, asks for phone and optional styling requests.
5. **Step 5 — Confirmation & Summary:** Displays a receipt-style card. Clicking **Confirm Appointment** triggers an atomic database transaction.
6. **Double-Booking Protection:** If two clients try to book the same slot simultaneously, SQLite's unique index constraint `idx_unique_active_slot` rejects the duplicate with an HTTP 409 Conflict error.

---

## 12. How Admin Panel Works

Access the admin panel at **`/admin`**.
It is built with clear visual controls, large buttons, toggle switches, and no technical jargon:
- **Dashboard:** Overview cards showing Today's bookings, Pending, Confirmed, Completed, Cancelled, and Total Revenue.
- **Appointments Table:** Filter by date, status, or service, or search by customer name/email/ID. Change status between Pending, Confirmed, Completed, Cancelled, and No-show.
- **Calendar & Daily Agenda:** View day-by-day schedules and block specific hours.

---

## 13. How to Replace Images

1. Go to **Admin Panel &rarr; Lookbook Gallery** (`/admin/gallery`).
2. Click **"+ Add New Image"**.
3. Choose to either **Upload an Image File** from your computer or enter an **Image URL**.
4. Set a Style Title (e.g. "Textured Fade") and select a Category.
5. Save. The new image immediately appears on the public lookbook page.
6. You can delete or hide placeholder demo images at any time with a single click.

---

## 14. How to Change Services & Prices

1. Go to **Admin Panel &rarr; Services & Pricing** (`/admin/services`).
2. Click **"Edit"** on any existing service (e.g., Haircut).
3. Update the **Price (₹)**, **Duration (Minutes)**, or **Description**.
4. Click **"Save Changes"**.
5. The updated price is immediately reflected across the public website and in the booking calculation engine.

---

## 15. How to Change Business Information

1. Go to **Admin Panel &rarr; Website Content** (`/admin/content`).
2. Update shop details:
   - Phone Number
   - WhatsApp Number
   - Instagram Profile Link
   - Google Maps Link
   - Hero Headline & Subtitle
   - About Text & Why Choose Us Text
   - Cancellation Policy Window (Hours)
3. **Graceful Hiding:** If any field is left empty (e.g. phone or Instagram), the public website gracefully hides that item rather than showing placeholder or broken text.

---

## 16. How to Configure Opening Hours

1. Go to **Admin Panel &rarr; Business Hours** (`/admin/hours`).
2. For each day (Monday through Sunday):
   - Toggle **Open / Weekly Off**.
   - Set **Opening Time** (e.g., 09:00).
   - Set **Closing Time** (e.g., 21:00).
   - Configure optional **Break Period** (e.g., 13:00 to 14:00).
3. Use the **Master Booking Switch** to temporarily pause online bookings whenever needed.
4. Click **"Save Operating Hours"**.

---

## 17. How to Deploy Frontend

Because this application uses server-side rendered Jinja2 with modern CSS/JS:
- The frontend and backend are served together seamlessly by FastAPI without requiring a separate static site build step.
- If you wish to separate the frontend onto Vercel / Netlify with Next.js, all public API endpoints (`/api/public/info`, `/api/public/services`, `/api/public/availability`, `/api/bookings/create`) are already fully structured and return clean JSON payloads.

---

## 18. How to Deploy Backend

### Option A: Railway / Render / Fly.io / Heroku (Easiest)
1. Push this repository to GitHub.
2. Create a new Web Service on [Render](https://render.com) or [Railway](https://railway.app).
3. Set the start command:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port $PORT
   ```
4. Set the environment variable `SECRET_KEY` in the service dashboard.

### Option B: Ubuntu / Debian VPS (DigitalOcean / Linode / AWS EC2)
1. Install Python 3.11 and Git.
2. Set up systemd service `/etc/systemd/system/stylezone.service`:
   ```ini
   [Unit]
   Description=The Stylezone Production Web Application
   After=network.target

   [Service]
   User=www-data
   WorkingDirectory=/var/www/the-stylezone
   ExecStart=/var/www/the-stylezone/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```
3. Put Nginx in front as a reverse proxy with SSL via Let's Encrypt Certbot.

---

## 19. How to Deploy Database

- **SQLite (Default):** Ready out-of-the-box. Uses WAL journaling, busy timeout retry logic, and automatic SQL snapshot sync (`data/the_stylezone.sql`). When deploying on Render/Railway/Fly.io, attach a persistent volume to preserve the database file across redeployments.
- **Migrating to PostgreSQL:** The database schema is ANSI-SQL compliant. To switch to PostgreSQL, simply change `sqlite3` queries to `psycopg2` or `asyncpg` with a `DATABASE_URL=postgresql://user:pass@host/dbname` connection string.

---

## 20. Future Payment Integration Location

Online payment is intentionally **not required** right now. Every appointment is booked with payment method set to `cash_at_counter` and payment status `unpaid`.

When the business decides to accept online payments:
1. **Database Schema:** The `appointments` table already includes `payment_status` ('unpaid', 'paid', 'cash_at_counter') and `payment_method` ('cash_at_counter').
2. **Backend Gateway Hook:** In `app/routers/booking.py`, inside `create_booking_api`, after `create_booking_atomic()` succeeds, initialize the order with your payment provider:
   - **Razorpay:** `client.order.create({"amount": int(service_price * 100), "currency": "INR", "receipt": booking_id})`
   - **Stripe:** `stripe.PaymentIntent.create(amount=int(service_price * 100), currency='inr', metadata={'booking_id': booking_id})`
3. **Frontend Hook:** In `app/static/js/booking.js`, inside `submitFinalBooking()`, open the Razorpay/Stripe checkout modal and redirect to `/booking-confirmation/{booking_id}` upon payment verification.

---

## Summary of Confirmed Business Details

| Item | Details |
|---|---|
| **Business Name** | The Stylezone |
| **Address** | Street no 32, Vipin Garden Extension, Dwarka Mor, Delhi |
| **Confirmed Services** | 1. Haircut (₹100)<br>2. Beard (₹70)<br>3. Haircut + Beard (₹150)<br>4. Facial (₹300)<br>5. D-Tan (₹300) |
| **Aesthetic** | Luxury Black & Gold, Dark/Light Mode, Mobile-First |
