# Mio — Cross-Platform AI Chatbot
### Arun Teja Vemula

---

## Slide 1: What Is Mio?

Mio is a **production-ready, cross-platform AI chatbot** built with a single Flutter codebase and a FastAPI backend. Users can chat with an AI assistant across Android, iOS, Web, Windows, macOS, and Linux — all from the same codebase.

**The core problem it solves:** Building a chatbot that works everywhere — with real auth, payments, async AI tasks, and file exports — without maintaining multiple codebases.

---

## Slide 2: Key Features

| Feature | Description |
|---|---|
| **Multi-platform** | One Flutter codebase → Android, iOS, Web, Windows, macOS, Linux |
| **AI Chat** | Streamed responses via configurable AI service |
| **Async Tasks** | Research + agent tasks via Celery workers |
| **File Export** | Download conversations as PDF or DOCX |
| **Token Billing** | Usage-tracked token system with top-up |
| **Payments** | Stripe (international) + Razorpay (India) |
| **JWT Auth** | AES-256 encrypted API keys, secure storage |
| **Rate Limiting** | Per-endpoint limits via Upstash Redis |
| **Search** | Full-text search across chat history |

---

## Slide 3: Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                           │
│     Android | iOS | Web | Windows | macOS | Linux       │
│  Riverpod · go_router · Dio · flutter_secure_storage   │
└────────────────────────┬────────────────────────────────┘
                         │ HTTPS (JWT)
┌────────────────────────▼────────────────────────────────┐
│               FastAPI Backend (Railway)                  │
│  auth · chat · export · payments · webhooks · search   │
│  JWT middleware · AES-256 encryption · rate limiting   │
├──────────┬──────────────┬────────────────┬──────────────┤
│ Supabase │  AI Service  │    Celery       │   Stripe /   │
│ (Postgres│  (inference) │  + Upstash Redis│   Razorpay  │
│  + RLS)  │              │  (async tasks)  │             │
└──────────┴──────────────┴────────────────┴──────────────┘
```

**Key rule:** The Flutter app never calls Supabase directly — everything goes through the FastAPI backend.

---

## Slide 4: Tech Stack

### Frontend
- **Flutter + Dart ^3.8** — single codebase, all platforms
- **Riverpod** — state management
- **go_router** — declarative routing
- **Dio** — HTTP client
- **flutter_secure_storage** — secure JWT + key storage
- **json_serializable** — type-safe model generation

### Backend
- **FastAPI 0.115** — async Python web framework
- **Python 3.11** — type-hinted throughout
- **Pydantic v2** — schema validation
- **Supabase** — PostgreSQL with Row Level Security
- **Celery 5.4** — distributed task queue
- **Upstash Redis** — Celery broker + rate limiter
- **slowapi** — per-endpoint rate limiting

---

## Slide 5: Payments & Billing

Mio supports two payment processors to handle a global user base:

**Stripe (International)**
- Subscription and one-time token top-up
- Webhook handler for payment events
- Handles USD, EUR, and major currencies

**Razorpay (India)**
- INR payments for Indian users
- Separate webhook handler
- Token credited on successful payment confirmation

**Token System**
- Every AI inference consumes tokens
- `token_guard` middleware blocks requests when balance is 0
- `token_service` tracks usage per user
- Users top up via either payment processor

---

## Slide 6: Security Architecture

| Layer | Implementation |
|---|---|
| **Authentication** | JWT (python-jose), verified on every request via `auth_middleware` |
| **API Key Storage** | AES-256 encrypted server-side via `encryption_service` |
| **Database** | Row Level Security (RLS) enabled on all Supabase tables |
| **Rate Limiting** | Per-endpoint limits via slowapi + Upstash Redis |
| **Client Storage** | flutter_secure_storage — no plain-text secrets on device |
| **Type Safety** | No dynamic types in Flutter; strict null safety |

---

## Slide 7: Async Task System

Long-running AI operations run as Celery tasks — not blocking the HTTP request/response cycle.

```
User Request
     │
     ▼
FastAPI Route  ──►  Celery Task Queue (Upstash Redis)
     │                        │
     │ (returns task_id)      ▼
     ◄──────────────  Worker executes:
                        · agent_task    (multi-step AI agent)
                        · research_task (web research + synthesis)
                        · file_task     (PDF / DOCX generation)
```

Two Railway services run independently: the FastAPI server and the Celery worker.

---

## Slide 8: Design System

| Token | Value | Usage |
|---|---|---|
| **Primary accent** | Persian Orange `#CC5801` | Interactive elements only |
| **Light background** | Warm cream `#FAF8F5` | Light mode |
| **Dark background** | Pure black `#000000` | Dark mode |
| **Body font** | DM Sans | All body text |
| **Heading font** | DM Serif Display | Titles and headings |
| **Mascot** | Kawaii ghost with devil horns | Onboarding, empty states |

---

## Slide 9: Project Structure

```
Chatbot_Mio/
├── frontend/lib/
│   ├── core/           # theme, router, utils
│   ├── data/           # models, services, repositories, providers
│   └── presentation/   # screens and widgets
├── backend/app/
│   ├── routers/        # 11 route modules
│   ├── services/       # 10 service modules
│   ├── models/         # Pydantic schemas
│   ├── middleware/     # JWT + security
│   ├── tasks/          # Celery task definitions
│   └── worker.py       # Celery app config
├── app/                # Experimental voice + projects API
├── supabase/           # DB migrations + RLS policies
└── docs/               # Feature specs
```

---

## Slide 10: Deployment

Both backend services deploy to **Railway** with zero-config Docker builds:

```
Service 1 (API):    uvicorn main:app --host 0.0.0.0 --port $PORT
Service 2 (Worker): celery -A app.worker.celery_app worker
```

**Infrastructure:** Railway · Supabase (managed Postgres) · Upstash Redis · Resend (email)

**Frontend** builds to static files deployable to any CDN.

---

## Slide 11: Skills Demonstrated

- **Cross-platform mobile/desktop** — Flutter clean architecture, Riverpod, go_router
- **Production API design** — FastAPI, Pydantic v2, JWT auth, AES-256 encryption
- **Distributed systems** — Celery task queue, Redis broker, async workers
- **Payment integration** — Stripe + Razorpay, dual-currency billing, webhooks
- **Database design** — Supabase PostgreSQL, Row Level Security, migrations
- **Security engineering** — End-to-end security from device storage to DB
- **DevOps** — Railway deployment, Docker, multi-service architecture

---

## Summary

Mio is a full-stack, production-quality AI chatbot demonstrating:
- Single Flutter codebase across 6 platforms
- Secure, scalable FastAPI backend with async task processing
- International payment support with token-based billing
- Clean architecture, strict typing, and layered security throughout

> **Stack:** Flutter · Dart · FastAPI · Python · Supabase · Celery · Upstash Redis · Stripe · Razorpay · Railway
