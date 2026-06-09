# Mio — Cross-Platform AI Chatbot

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)](https://supabase.com)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python)](https://python.org)
[![Dart](https://img.shields.io/badge/Dart-3.8-0175C2?logo=dart)](https://dart.dev)

Mio is a production-ready AI chatbot application with a single Flutter codebase that targets mobile, web, and desktop. The FastAPI backend handles AI inference, async research tasks, file exports, token-based billing, and international payments — all deployed on Railway.

---

## Features

- **Multi-platform**: One Flutter codebase runs on Android, iOS, Web, Windows, macOS, Linux
- **AI chat**: Streamed responses via configurable AI provider (ai_service)
- **Async tasks**: Research and agent tasks via Celery workers backed by Upstash Redis
- **File export**: Export conversations as PDF or DOCX
- **Token billing**: Token guard, usage tracking, token top-up
- **Payments**: Stripe (international) + Razorpay (India) with webhook handling
- **Auth**: JWT-based authentication with AES-256 encrypted API key storage
- **Rate limiting**: Per-endpoint rate limits via slowapi + Upstash Redis
- **Search**: Full-text search across conversation history
- **Settings sync**: Device management, notification preferences

---

## Architecture

```
Chatbot_Mio/
├── frontend/          # Flutter app (clean architecture)
│   └── lib/
│       ├── core/          # theme, router (go_router), utils
│       ├── data/
│       │   ├── models/    # json_serializable Dart models
│       │   ├── services/  # HTTP via Dio
│       │   ├── repositories/
│       │   └── providers/ # Riverpod state
│       └── presentation/
│           ├── screens/   # auth, chat, settings, projects, legal
│           └── widgets/
├── backend/           # FastAPI — main production backend (Railway)
│   └── app/
│       ├── routers/   # auth, chat, export, files, keys, tokens,
│       │              # devices, settings, payments_stripe,
│       │              # payments_razorpay, webhooks
│       ├── services/  # ai, email, encryption, export, file,
│       │              # geo, rate_limiter, search, token_guard
│       ├── models/    # Pydantic schemas
│       ├── middleware/ # JWT auth, security
│       ├── tasks/     # Celery: agent_task, file_task, research_task
│       └── worker.py  # Celery app (Upstash Redis broker)
├── app/               # Secondary/experimental API (voice + projects)
├── supabase/          # DB migrations, RLS policies
└── docs/              # Specs
```

### Data Flow

```
Flutter app  ──►  FastAPI backend  ──►  Supabase (PostgreSQL)
                       │
                       ├──►  AI provider (ai_service)
                       ├──►  Celery workers  ──►  Upstash Redis
                       ├──►  Stripe / Razorpay
                       └──►  Resend (email)
```

**Key rule**: Flutter never calls Supabase directly — all data flows through the FastAPI backend.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter + Dart ^3.8, Riverpod, go_router, Dio, flutter_secure_storage |
| Backend | FastAPI 0.115, Python 3.11, Pydantic v2, uvicorn |
| Database | Supabase (PostgreSQL) with RLS on all tables |
| Async | Celery 5.4 + Upstash Redis |
| Payments | Stripe 10.x (international), Razorpay 1.4 (India) |
| Auth | JWT (python-jose), AES-256 encryption (cryptography) |
| Email | Resend |
| Export | pypdf, python-docx, reportlab |
| Deployment | Railway (backend + Celery worker as separate services) |

---

## Design System

| Token | Value |
|---|---|
| Primary accent | Persian Orange `#CC5801` |
| Light background | Warm cream `#FAF8F5` |
| Dark background | Pure black `#000000` |
| Body font | DM Sans |
| Heading font | DM Serif Display |
| Mascot | Kawaii ghost with devil horns |

---

## Getting Started

### Backend

```bash
cd backend
pip install -r requirements.txt
cp ../.env.example .env   # fill in secrets
uvicorn main:app --reload --port 8000
```

Start Celery worker (separate terminal):

```bash
cd backend
celery -A app.worker.celery_app worker --loglevel=info --concurrency=2
```

Required env vars: `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `JWT_SECRET`, `ENCRYPTION_KEY`, `STRIPE_SECRET_KEY`, `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `UPSTASH_REDIS_URL`, `RESEND_API_KEY`.

### Frontend

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run                  # connected device / emulator
flutter run -d chrome        # web
flutter run -d windows       # desktop
```

---

## Security

- JWT verified on every request via `auth_middleware`
- All API keys stored AES-256 encrypted server-side
- RLS enabled on all Supabase tables as a backup security layer
- Rate limiting on every endpoint (slowapi + Upstash Redis)
- No dynamic types in Flutter — strict null safety throughout

---

## Deployment

Backend and Celery worker each deploy as separate Railway services using the root `Dockerfile`.

```
Railway service 1: uvicorn main:app --host 0.0.0.0 --port $PORT
Railway service 2: celery -A app.worker.celery_app worker
```

---

## License

MIT
