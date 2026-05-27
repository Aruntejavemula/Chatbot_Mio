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
| User bubble bg | `#EDE9E3` | `#1A1A1A` |
| User bubble border | `#D8D2CA` | `#2A2A2A` |

**Typography** (unchanged): DM Sans body, DM Serif Display headings.  
**Mascot**: Kawaii brown penguin (existing asset). Must be transparent PNG — strip white background from JPEG before use. Shown sparingly: empty state, splash only.

---

## 2. Chat Screen — Message Style

**Pattern: Borderline minimal (no bubbles)**

Each message is a full-width block differentiated by a 2px left border accent, role label, and text color — no rounded bubble containers.

### AI message
```
[2px #CC5801 left border]
MIO  ← 10px, #8A8078 light / #555048 dark, letter-spacing 0.8px, uppercase
<response text>  ← 15px DM Sans, #0A0A0A light / #E8E4DE dark, line-height 1.7
```

### User message
```
[2px #D8D2CA light / #2A2A2A dark left border]
YOU  ← 10px, #8A8078, uppercase
<message text>  ← 15px DM Sans, #3A3530 light / #AAA dark, line-height 1.7
```

### Code blocks (inside AI messages)
- Background: `#F5F1EB` light / `#111` dark
- Left border: 3px `#CC5801`
- Font: monospace 13px
- Border radius: 6px

### Timestamps
- Show on hover (desktop) / long-press (mobile)
- Format: `2:34 PM`, color `#8A8078` / `#444`

### Message spacing
- Gap between messages: 20px
- Padding: 20px horizontal, 16px vertical per message block

---

## 3. Sidebar — Floating Card

The sidebar is a rounded floating card, slightly inset from screen edges on desktop.

### Structure (top to bottom)
1. **Search + New Chat row** — search input left, orange `+` button right
2. **Projects section** (pro users) — collapsed by default, expand on tap
3. **Chat history** — grouped by TODAY / YESTERDAY / LAST 7 DAYS / LAST 30 DAYS
4. **Bottom user row** — avatar, name, plan badge, settings icon

### Card styling
- Background: `#F0EDE8` light / `#0D0D0D` dark
- Border: 1px `#E0DAD2` light / `#1A1A1A` dark
- Border radius: `16px` (desktop permanent), `0` top + `16px` bottom-right (mobile drawer)
- On desktop: 4px margin from top/bottom edges, flush to left

### Active chat item
- Left border: 3px `#CC5801`
- Background: `#FAF8F5` light / `#161616` dark
- Text: primary color

### New Chat button
- Background: `#CC5801`
- Icon: `+` white, 18px
- Size: 36×36px, border-radius 10px

### Search bar
- Background: `#E8E4DE` light / `#111` dark
- Border: 1px `#D8D2CA` light / `#1E1E1E` dark
- Height: 38px, border-radius 10px
- Icon: search, 16px muted

### Bottom user row
- Avatar: 30px circle, initials in `#CC5801` on `#1A1A1A` bg
- Plan badge: pill, `FREE` in muted / `PRO` in `#CC5801`
- Settings: gear icon, muted, taps to settings screen

---

## 4. Input Bar — Floating Pill

The input bar floats above the screen bottom edge — not anchored full-width.

### Container
- Margin from screen edges: 12px horizontal, 12px bottom
- Background: `#FAF8F5` light / `#0D0D0D` dark
- Border: 1px `#CC580133` (orange at 20% opacity) — always, not just on focus
- Border radius: `28px` (full pill)
- Box shadow: `0 4px 24px rgba(204,88,1,0.07)` — subtle orange glow
- On focus: border becomes `#CC5801` at 60% opacity, glow intensifies

### Contents (left to right)
1. `+` button — opens attachment panel, rotates 45° when open, 22px muted
2. Prompt maker icon (sparkle/wand) — only when has text
3. Text field — 15px DM Sans, expands up to 6 lines
4. Mic button — only when no text, 20px muted
5. Send button — 36×36px circle, `#CC5801` bg when has text / `#3A3530` when empty, white arrow icon

### Disclaimer
- Below pill: `Mio can make mistakes` — 11px muted, centered
- Dismissible (persisted in SharedPreferences)

---

## 5. Empty State (New Chat)

Shown when chat has no messages.

### Layout (centered vertically)
1. Penguin mascot — 72px, transparent PNG (`assets/images/penguin.png`)
2. Greeting heading — `What's on your mind?` — 22px DM Serif Display, primary color
3. Subtext — `Ask me anything` — 13px muted
4. Prompt chips — 4 chips, 2×2 grid on mobile / row on desktop

### Prompt chips
- Background: `#EDE9E3` light / `#111` dark
- Border: 1px `#D8D2CA` light / `#1E1E1E` dark
- Border radius: `20px`
- Padding: `6px 14px`
- Text: 12px DM Sans, muted color
- Content: `✍️ Write something`, `🔍 Research a topic`, `💻 Help with code`, `📋 Summarize this`
- Tapping chip fills the input field, focuses it

---

## 6. Top Bar

Minimal. No heavy chrome.

### Empty state
- Center: `Mio` in DM Serif Display 18px primary
- Left: hamburger (mobile only), settings icon (desktop only, links to settings)
- Right: nothing

### Active chat
- Center: chat title, 15px DM Sans semibold, truncated
- Left: hamburger (mobile) or nothing (desktop with permanent sidebar)
- Right: share icon, export icon, `⋯` more options

### Styling
- Background: same as screen bg (transparent feel)
- Border bottom: 1px default border color
- Height: 52px

---

## 7. Model Selector Bar

Sits below top bar. Compact. Left-aligned pill.

- Pill: `14px DM Sans`, selected model name, chevron
- When no model selected: text is `#CC5801` "Select model"  
- Pill bg: tertiary bg, border default
- Dropdown: floating card, grouped by provider, search field at top
- Active model: checkmark in `#CC5801`

---

## 8. Mascot Usage Rules

- **Splash screen**: 80px centered, no animation beyond fade-in
- **Empty chat state**: 72px, static
- **Nowhere else in main app UI**
- Asset must be transparent PNG — current `PenguinMascot` widget wraps it

---

## 9. Screen-by-Screen Summary

| Screen | Key changes |
|---|---|
| Splash | Penguin 80px centered, cream/black bg, fade in |
| Welcome/Login | Penguin 72px, `Mio` serif heading, auth buttons styled with new colors |
| Onboarding | Cards use new bg/border tokens, orange CTA button |
| Chat (empty) | Penguin 72px, greeting, 4 prompt chips |
| Chat (active) | Borderline minimal messages, floating pill input, top bar |
| Sidebar | Floating card, orange active state, new search/new-chat design |
| Settings | Clean list, persian orange for active/selected states |
| Auth screens | Form inputs use new border/bg tokens, orange focus border |

---

## 10. Assets Required

| Asset | Format | Notes |
|---|---|---|
| `assets/images/penguin.png` | PNG transparent | Remove white bg from existing JPEG |
| Existing font assets | — | DM Sans + DM Serif Display already in pubspec |

---

## 11. Out of Scope

- Backend changes
- New features (voice, deep research, etc.)
- Navigation restructuring
- Settings screen deep redesign
- Payments/subscription screens
