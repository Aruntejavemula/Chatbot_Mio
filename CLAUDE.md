# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mio is a cross-platform AI chatbot app. Flutter frontend (single codebase, all platforms) + FastAPI backend deployed on Railway + Supabase database. Payments via Stripe (international) and Razorpay (India). Async tasks via Celery with Upstash Redis.

## Repository Structure

There are two backend entry points:
- `backend/` — Main production backend (deployed to Railway). Has its own `app/` with routers, services, models, middleware, tasks, utils.
- `app/` — Secondary/experimental API at repo root (voice + projects only). Separate config and requirements.

Frontend lives in `frontend/` — standard Flutter clean architecture.

## Commands

### Backend (from `backend/`)
```bash
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
celery -A app.worker.celery_app worker --loglevel=info --concurrency=2
```
Python 3.11. Config via `backend/.env` (copy `.env.example`).

### Frontend (from `frontend/`)
```bash
flutter pub get
flutter run                    # run on connected device/emulator
flutter run -d chrome          # web
flutter run -d windows         # desktop
dart run build_runner build --delete-conflicting-outputs  # regenerate .g.dart files
flutter analyze                # lint
flutter test                   # all tests
flutter test test/path_test.dart  # single test
```
Dart SDK ^3.8.0.

## Architecture

### Backend (`backend/app/`)
- **routers/** — FastAPI route handlers (auth, chat, export, files, keys, tokens, devices, settings, payments_stripe, payments_razorpay, webhooks)
- **services/** — Business logic (ai_service, email, encryption, export, file, geo, rate_limiter, search, token_guard, token_service)
- **models/** — Pydantic models (chat, device, payment, token, user)
- **middleware/** — auth_middleware (JWT verification), security_middleware
- **tasks/** — Celery async tasks (agent_task, file_task, research_task)
- **worker.py** — Celery app config, uses Upstash Redis as broker

Config loaded via `app/config.py` using pydantic-settings `BaseSettings` with `@lru_cache`.

### Frontend (`frontend/lib/`)
- **core/** — constants, theme (AppTheme.light/dark), utils (router via go_router, animations, responsive helpers)
- **data/models/** — json_serializable models (`.g.dart` generated)
- **data/services/** — HTTP services calling backend API via Dio
- **data/repositories/** — auth, chat, settings repositories
- **data/providers/** — Riverpod providers
- **presentation/screens/** — auth, chat, launch, legal, projects, settings, splash
- **presentation/widgets/** — reusable widgets

State management: flutter_riverpod. Routing: go_router. HTTP: Dio. Storage: flutter_secure_storage.

## Key Rules (from RULES.md)

- **Never work on main branch** — all work on `feature/feature-name` branches
- **Frontend never calls Supabase directly** — all data flows through FastAPI backend
- **Frontend only stores**: backend URL, Stripe publishable key, Razorpay key ID, JWT token
- **All API keys encrypted AES-256** server-side via encryption_service
- **Rate limiting on every endpoint** via Upstash Redis (slowapi)
- **JWT verified on every request** via auth_middleware
- **RLS enabled on all Supabase tables** as backup security layer
- **No dynamic types in Flutter** — strict null safety
- **Type hints on every Python function**
- **Commit format**: `type: description` (feat, fix, refactor, test, docs)

## Design System

- Primary accent: Persian Orange `#CC5801` (use sparingly, critical interactive elements only)
- Light background: `#FAF8F5` (warm cream)
- Dark background: `#000000` (pure black)
- Fonts: DM Sans (body) + DM Serif Display (headings) via google_fonts
- Mascot: kawaii ghost with devil horns (shown sparingly)

## Deployment

Backend deploys to Railway (nixpacks builder). Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`. Celery worker runs as separate Railway service.
