# IMPORTANT — READ THIS FIRST
This file must be read at the start of
every single Kiro session before any work.
All rules here are non negotiable.
Never break any rule in this file.
Never work on main branch.
Never expose secrets in frontend.
Frontend never calls Supabase directly.
All work on feature branches only.

# Mio App — Project Rules

## Branch Strategy
- Never work on main branch directly
- All work goes on feature branches
- Branch naming: feature/feature-name
- Example: feature/auth, feature/chat-ui
- Main branch = production only
- Never auto merge to main
- All merges require manual review

## Security Rules
- Frontend never connects to Supabase directly
- Frontend never stores any secret keys
- Frontend only calls FastAPI backend
- Frontend only has:
  Railway backend URL
  Stripe publishable key (safe)
  Razorpay key ID (safe)
  JWT token after login
- All business logic lives in backend only
- All AI API keys live in backend only
- All Supabase keys live in backend only
- Backend uses Supabase service role key
- RLS enabled on all tables as backup layer
- All API keys encrypted AES-256 server side
- JWT verified on every single backend request
- No exceptions

## Rate Limiting
- Every endpoint has rate limiting
- Auth endpoints: 5 requests per minute per IP
- Chat endpoints: 10 requests per minute per user
- Payment endpoints: 3 requests per minute per user
- General endpoints: 60 requests per minute per user
- Rate limiting via Upstash Redis
- Exceeded limits return 429 Too Many Requests

## Code Quality Rules
- Less code is better than more code
- Every function does one thing only
- No duplicate code ever
- No commented out code
- Clear variable names always
- No magic numbers, use constants
- Error handling on every function
- Type safety everywhere
- Flutter: strict null safety always
- Python: type hints on every function

## Testing Rules
- Tests written after features are stable
- Not during initial build
- Unit tests for all business logic
- Integration tests for all API endpoints
- Widget tests for critical Flutter screens
- Test coverage minimum 70%
- Tests live in /tests folder

## Database Rules
- Frontend never calls Supabase directly
- All DB calls go through FastAPI only
- RLS enabled on all tables
- Row Level Security as backup layer
- Backend uses service role key
- No raw SQL in application code
- Use Supabase client methods only
- All queries have error handling

## Flutter Rules
- Strict null safety always
- No dynamic types
- Proper state management (Riverpod)
- Separate UI from business logic
- No business logic in widgets
- Services handle all API calls
- Models handle all data
- Clean architecture pattern:
  lib/
    core/         constants, theme, utils
    data/         models, services, repositories
    presentation/ screens, widgets, providers
    main.dart

## FastAPI Rules
- All routes have authentication middleware
- All inputs validated with Pydantic
- All errors return consistent format
- All endpoints documented with docstrings
- Logging on every endpoint
- No print statements, use logging
- Environment variables for all secrets
- Never hardcode any values

## File Structure Rules
Frontend (Flutter):
  lib/
    core/
      constants/
      theme/
      utils/
    data/
      models/
      services/
      repositories/
    presentation/
      screens/
      widgets/
      providers/
    main.dart

Backend (FastAPI):
  app/
    routers/
    services/
    models/
    middleware/
    utils/
  tests/
  main.py
  requirements.txt
  .env (never committed)
  .env.example (committed)

## Git Rules
- Commit messages must be clear
- Format: type: description
- Types: feat, fix, refactor, test, docs
- Example: feat: add Google auth endpoint
- Never commit .env files
- Never commit API keys
- .gitignore covers all secrets

## Design System
- App name: Mio
- Primary accent: Persian Orange #CC5801
- Use Persian Orange sparingly
- Only on critical interactive elements
- Light mode background: #FAF8F5 warm cream
- Dark mode background: #000000 pure black
- Font: DM Sans (body) + DM Serif Display (headings)
- Mascot: cute kawaii ghost with devil horns
- Mascot shown sparingly, not on every screen
- App name "Mio" shown only on:
  Splash screen
  Welcome/login screen
  App Store listing
  Not in main app UI

## Platform Targets
- iOS (Xcode + Flutter)
- iPadOS (same code as iOS)
- Android (Android Studio + Flutter)
- Web/PWA (Vercel)
- macOS (Xcode + Flutter)
- Windows (Visual Studio + Flutter)
- Single Flutter codebase for all platforms
- Single FastAPI backend for all platforms
- Single Supabase DB for all platforms

## What We Never Do
- Never expose secrets in frontend
- Never work on main branch
- Never skip error handling
- Never use dynamic types in Flutter
- Never call DB from frontend
- Never store unencrypted API keys
- Never auto merge to main
- Never skip rate limiting
- Never hardcode values
- Never commit .env files
