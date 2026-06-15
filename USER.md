# Ruddy Ribera — User Profile

## Identity
- **Name:** Ruddy Ribera — ruddyribera@gmail.com
- **Location:** Bolivia (GMT-4)
- **Language:** Spanish primary, English for technical terms, mixed → Spanish

## Professional Identity
- **5th-grade tutor**, K-12 Technology teacher, freelance English instructor, pedagogical consultant
- **Independent EdTech founder** — sole developer of an advanced educational technology suite
- **Pedagogical approach:** neuro-inclusive design, clear visual scaffolding, specialized student roles, gamification
- **Workflow:** high-executive function / "StarCraft-style" multitasking, complete architectural autonomy, highly autonomous execution

## How You Work
- **Direct, fast, no fluff.** Tell you what, not how.
- **Proceed without asking** once intent is clear on non-destructive work
- **Announce risky actions** in one sentence before executing
- **Verify before acting —** don't assume local = remote

## OS & Shell
- Windows 11, PowerShell as primary shell
- Commands shown to user: **PowerShell syntax ONLY**
- `&&` forbidden in user commands, `$env:FOO='bar'` not `export FOO=bar`
- Git Bash runs agent internals (POSIX OK there)

## Tech Stack Comfort
Git · Railway · Python · JS · TypeScript · Node.js · Streamlit · FastAPI · Laravel 11 · Next.js 14 · React 19 · Vite · Express.js · PostgreSQL · Redis · Docker Compose · bcrypt · WebSocket · Google Gemini · Claude · MiniMax

---

## Your 7 GitHub Repos (github.com/ruddyribera-ops)

### PRIA — Palma-Ribera Instructional Agent (PRIVATE)
- **What:** EdTech AI assistant (AID/TIA) + Daily Tracker for teachers
- **Stack:** Python 3.10, Streamlit, FastAPI, PostgreSQL on Railway
- **Deploy:** https://priav5-production.up.railway.app
- **Local:** `C:\Users\Windows\Desktop\02_Proyectos\PRIA\PRIA DEPLOY`
- **Beta:** Las Palmas school pilot ~3 weeks out
- **Critical:** Fresh deploy = empty DB. Seed-on-startup is load-bearing.

### Palma Coin — Gamified Classroom Economics (PUBLIC)
- **What:** Students earn Palma Coins, real-time voting, reward redemption
- **Stack:** Node.js + Express + pg, React 19 + Vite, WebSocket, bcrypt
- **Deploy:** https://palma-coin-production.up.railway.app
- **Known:** WebSocket broken on Railway TCP proxy (production issue)
- **Test:** ruddy@laspalmas.edu.bo / palma2026

### Math Platform (PUBLIC — `perfectpractice`)
- **What:** Khan Academy + Duolingo-style adaptive math platform
- **Stack:** Python 3.12 FastAPI + SQLAlchemy async, Next.js 14, TypeScript, PostgreSQL, Redis, Docker Compose
- **Local:** `C:\Users\Windows\math-platform`
- **Phase 11 complete** — G1-G6 curriculum, BarModel/WordProblem renderers

### EduFlow — School CRM (PUBLIC)
- **What:** Admissions Kanban, student tracking, AI at-risk detection, emergency broadcast
- **Stack:** Laravel 11 (PHP 8.3) + Next.js 14 (TypeScript, TailwindCSS, shadcn/ui) + PostgreSQL 16 + Redis
- **Features:** FERPA-compliant (RLS), AI at-risk alerts, Twilio SMS broadcast, drag-drop Kanban
- **Deploy:** Docker + Railway (backend + frontend separate services)

### BDM App — Gemini Document Pipeline (PUBLIC)
- **What:** NGOs upload PDFs/DOCXs → Gemini AI generates annual reports
- **Stack:** Vite + React 19, Express.js, Google Gemini, Vitest
- **Deploy:** https://bdm-app-prod-production.up.railway.app
- **Refactor:** Phase A-F complete (App.jsx 1053→449 lines, 7 components, CI)

### EduFlow Optimizer — OpenCode Setup (PUBLIC — `opencode-power-setup`)
- **What:** One-click installer for project-aware OpenCode tooling with memory, skills, automation

### PC Optimizer AI (PUBLIC)
- **What:** AI PC Optimizer Cloud Service — FastAPI + HTML dashboard
- **Deploy:** Railway or Render
- **Note:** Production tasks are simulated — full function requires local agent on each PC

---

## Key Lessons (Never Forget)
1. Railway ephemeral filesystem — use Postgres plugin, never SQLite/sql.js on disk
2. `x-user-role` header spoofable — validate via DB/JWT server-side
3. WebSocket on Railway needs explicit TCP proxy config
4. PostgreSQL: `RETURNING *` not `last_insert_rowid()`
5. Seeds: always `ON CONFLICT DO NOTHING` (idempotent)
6. Always `git fetch` before touching code
7. Railway pink 404 = container not serving — check `railway logs`

---

## Personality
Building the future of Bolivian education through technology. Solo dev, independent founder. 7 active projects across EdTech, gamification, and AI. Wants working software for teachers and students. Skeptical of complexity for its own sake. Runs on autonomy and execution speed.
