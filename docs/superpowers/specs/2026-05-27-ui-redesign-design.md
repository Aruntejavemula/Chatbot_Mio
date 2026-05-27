# Mio UI Redesign — Design Spec
**Date:** 2026-05-27  
**Status:** Approved  
**Scope:** Full UI redesign across all screens — Flutter frontend only, no backend changes.

---

## 1. Design Identity

Mio uses its own visual identity — not copying any single app.

| Token | Light Mode | Dark Mode |
|---|---|---|
| Background primary | `#FAF8F5` (warm cream) | `#000000` (pure black) |
| Background secondary | `#F0EDE8` | `#0D0D0D` |
| Background tertiary | `#E8E4DE` | `#161616` |
| Border default | `#E0DAD2` | `#1E1E1E` |
| Text primary | `#0A0A0A` | `#FAF8F5` |
| Text secondary | `#3A3530` | `#C8C4BC` |
| Text muted | `#8A8078` | `#555048` |
| Accent (Persian Orange) | `#CC5801` | `#CC5801` |
| Accent hover | `#B34D00` | `#E06200` |

**Typography** (unchanged): DM Sans body, DM Serif Display headings.  
**Mascot**: Kawaii brown penguin (existing asset). Must be transparent PNG — strip white background from JPEG before use. Shown sparingly: empty state, splash only.

### Persian Orange usage rules

Persian Orange (`#CC5801`) is used **only** at these critical interactive elements:
- Send button (filled circle)
- Avatar initials background in sidebar bottom row
- Active chat item left border accent (3px)
- AI message left border accent (2px)
- Code block left border (3px)

**Nowhere else.** No orange borders on input, no orange plan badges, no orange model selector text, no orange on settings, no orange on chips. Everything else uses neutral tokens.

---

## 2. Chat Screen — Message Style

**Pattern: Borderline minimal (no bubbles)**

Each message is a full-width block differentiated by a 2px left border, role label, and text color. No rounded bubble containers.

### AI message
```
[2px #CC5801 left border]
MIO  ← 10px, #8A8078 light / #555048 dark, letter-spacing 0.8px, uppercase
<response text>  ← 15px DM Sans, #0A0A0A light / #E8E4DE dark, line-height 1.7
```

### User message
```
[2px #E0DAD2 light / #2A2A2A dark left border]
YOU  ← 10px, #8A8078 light / #555048 dark, uppercase
<message text>  ← 15px DM Sans, #3A3530 light / #C8C4BC dark, line-height 1.7
```

### Code blocks (inside AI messages)
- Background: `#F5F1EB` light / `#111` dark
- Left border: 3px `#CC5801`
- Font: monospace 13px
- Border radius: 6px

### Timestamps
- Show on hover (desktop) / long-press (mobile)
- Format: `2:34 PM`, color muted token

### Message spacing
- Gap between messages: 20px
- Padding: 20px horizontal, 16px vertical per message block

### Sending animation (Gemini-style glow)
When user sends a message, the user message block plays a brief glow pulse:
- Duration: 600ms total
- Keyframes: opacity 0→1 (150ms ease-out) + left border color pulses from `#CC5801` → `#E0DAD2` light / `#2A2A2A` dark (remaining 450ms ease-in-out)
- For AI: when streaming starts, left border fades in with same 150ms ease-out
- Implementation: `AnimationController` + `ColorTween` on the left border `Container`

---

## 3. Sidebar — Floating Card

The sidebar is a rounded floating card.

### Structure (top to bottom)
1. **Search + New Chat row** — search input left, new-chat button right
2. **Projects section** (pro users only) — collapsed by default
3. **Chat history** — grouped by TODAY / YESTERDAY / LAST 7 DAYS / LAST 30 DAYS
4. **Bottom user row** — avatar, name, plan badge, settings icon

### Card styling
- Background: `#F0EDE8` light / `#0D0D0D` dark
- Border: 1px `#E0DAD2` light / `#1A1A1A` dark
- Border radius: `16px` (desktop permanent), flush left + `16px` right side (mobile drawer)
- On desktop: 4px margin top/bottom, flush to left edge

### Active chat item
- Left border: 3px `#CC5801`
- Background: `#FAF8F5` light / `#161616` dark
- Text: primary color

### Inactive chat item
- No border
- Text: muted color
- Hover bg: `#EDE9E3` light / `#111` dark

### New Chat button
- Background: `#1A1A1A` dark / `#0A0A0A` light — **neutral, not orange**
- Icon: `+` white/cream 18px
- Size: 36×36px, border-radius 10px

### Search bar
- Background: `#E8E4DE` light / `#111` dark
- Border: 1px `#D8D2CA` light / `#1E1E1E` dark
- No focus orange — border stays neutral
- Height: 38px, border-radius 10px

### Bottom user row
- Avatar: 30px circle, initials white on `#CC5801` background ← **only orange here**
- Name: 14px DM Sans, primary color
- Plan badge: `FREE` — neutral bg, muted text. `PRO` — neutral bg, primary text. No orange.
- Settings: gear icon muted, taps to settings screen

---

## 4. Input Bar — Floating Pill

The input bar floats above screen bottom — not anchored full-width.

### Container
- Margin: 12px horizontal, 12px bottom
- Background: `#FAF8F5` light / `#0D0D0D` dark
- Border: 1px `#E0DAD2` light / `#1E1E1E` dark — **neutral always**
- Border radius: `28px` (full pill)
- Box shadow: `0 2px 12px rgba(0,0,0,0.08)` light / `0 2px 16px rgba(0,0,0,0.4)` dark — no orange glow
- On focus: border `#C8C4BC` light / `#2A2A2A` dark — slightly stronger but still neutral

### Contents (left to right)
1. `+` button — opens attachment panel, rotates 45° when open, 22px, muted color
2. Prompt maker icon (sparkle/wand) — only when has text, muted color
3. Text field — 15px DM Sans, expands up to 6 lines
4. Mic button — only when no text, 20px muted
5. Send button — 36×36px circle, **`#CC5801` bg when has text** ← orange only here / neutral `#3A3530` dark / `#8A8078` light when empty. White arrow icon.

### Disclaimer
- Below pill: `Mio can make mistakes` — 11px muted, centered
- Dismissible, persisted in SharedPreferences

---

## 5. Empty State (New Chat)

Shown when chat has no messages.

### Layout (centered vertically)
1. Penguin mascot — 72px transparent PNG (`assets/images/mascot.png`)
2. Greeting heading — 22px DM Serif Display, primary color — **Claude-style: short, warm, random per session. No time-of-day prefix.**
3. 3 mode tiles in a horizontal row

### Greeting pool (random per new chat session)
```dart
const greetings = [
  "How can I help?",
  "What's on your mind?",
  "What are we working on?",
  "Ready when you are.",
  "What can I do for you?",
  "Let's get to work.",
];
```
No subtext line. Just greeting heading — like Claude.

### Mode tiles (3 tiles)
- Size: ~80×80px each, border-radius 12px
- Background: `#EDE9E3` light / `#111` dark
- Border: 1px `#D8D2CA` light / `#1E1E1E` dark — **no orange**
- Icon: emoji 20px + label 11px DM Sans muted below
- Tiles: `✍️ Write`, `🔍 Research`, `💻 Code`
- Tap fills input with starter prompt, focuses it
- Mobile narrow: 2+1 wrap

---

## 6. Animations

**Principle: Apple-level premium. Fast, physical, never sluggish. Curves always ease-out or spring. Nothing linear.**

### Timing constants
```dart
// Fast interactions
const kDurationFast = Duration(milliseconds: 150);
// Standard transitions  
const kDurationStandard = Duration(milliseconds: 250);
// Emphasis / entry
const kDurationEmphasis = Duration(milliseconds: 350);

const kCurveDefault = Curves.easeOutCubic;
const kCurveSpring = SpringDescription(mass: 1, stiffness: 500, damping: 28);
```

### Per-interaction specs

| Interaction | Duration | Curve | Notes |
|---|---|---|---|
| Send button scale press | 150ms down, spring release | `easeOut` + spring | Scale 1.0 → 0.88 → 1.0 |
| Message entry | 200ms | `easeOutCubic` | Fade + slide up 8px |
| Sending glow pulse | 600ms | `easeOut` + `easeInOut` | Border color pulse (see §2) |
| Sidebar open/close (mobile) | 280ms | `easeOutCubic` | Slide from left |
| Model dropdown open | 200ms | `easeOutCubic` | Fade + scale from 0.96 |
| Input pill focus | 150ms | `easeOut` | Border color transition |
| `+` button rotation | 200ms | `easeOutCubic` | 0° → 45° |
| Prompt chip tap | 120ms | `easeOut` | Scale 1.0 → 0.95 → 1.0 |
| Screen transitions | 300ms | `easeOutCubic` | Slide right (go_router) |
| Scroll to bottom button | 200ms | `easeOut` | Fade in/out |
| Streaming text | Per character | — | Word-by-word fade-in, not instant |

### No-go list
- Never `linear` curves on anything visible
- Never durations > 400ms for UI responses (feels slow)
- No bounce that overshoots more than 4px
- No simultaneous animations on more than 2 elements

---

## 7. Top Bar

Minimal. No heavy chrome.

### Empty state
- Center: `Mio` in DM Serif Display 18px primary
- Left: hamburger (mobile only)
- Right: nothing

### Active chat
- Center: chat title, 15px DM Sans semibold, truncated
- Left: hamburger (mobile) or nothing (desktop permanent sidebar)
- Right: share icon, export icon, `⋯` more options — all muted, no orange

### Styling
- Background: same as screen bg
- Border bottom: 1px default border color
- Height: 52px

---

## 8. Model Selector Bar

Below top bar. Left-aligned pill. Compact.

- Pill bg: `#E8E4DE` light / `#161616` dark, border default
- Text: 14px DM Sans, primary color when model selected / muted when unselected ("Select model") — **no orange text**
- Chevron: muted, rotates on open
- Dropdown: floating card, neutral colors, grouped by provider, search at top
- Active model: checkmark in primary color (not orange)

---

## 9. Mascot Usage Rules

Mascot is a **Lottie animation** — handshake between Persian Orange hand (Mio/AI) and white hand (user). Pure vector, works on iOS, Android, Web/PWA, Windows, macOS, Linux.

- **Splash screen**: 80px, animates on loop
- **Welcome screen**: 80px, animates
- **Empty chat state**: 48px, animates
- **Auth screens**: 60px, animates
- **Nowhere else** (no chat messages, no settings lists)
- Asset: `assets/animations/mascot.json`
- Fallback (Lottie error): Persian Orange circle with white `M`

---

## 10. Screen-by-Screen Summary

| Screen | Key changes |
|---|---|
| Splash | Penguin 80px, cream/black bg, fade in |
| Welcome/Login | Penguin 72px, `Mio` serif heading, auth buttons neutral style |
| Onboarding | Cards use bg/border tokens, neutral CTA (no orange except final confirm) |
| Chat (empty) | Penguin 72px, greeting, 4 neutral chips |
| Chat (active) | Borderline minimal messages, glow on send, floating pill input |
| Sidebar | Floating card, orange only on active item border + avatar |
| Settings | Clean list, neutral colors throughout |
| Auth screens | Form inputs with cream bg, neutral focus border |

---

## 11. Assets Required

| Asset | Format | Notes |
|---|---|---|
| `assets/animations/mascot.json` | Lottie JSON | Handshake — Persian Orange hand (Mio) + white hand (user). Already copied. |
| Existing font assets | — | DM Sans + DM Serif Display already in pubspec |

---

## 12. Out of Scope

- Backend changes
- New features (voice, deep research, agent steps, etc.)
- Navigation restructuring
- Settings screen deep redesign
- Payments/subscription screens
