---
name: frontend-dev
description: Full-stack frontend development combining premium UI design, cinematic animations, AI-generated media assets, persuasive copywriting, and visual art. Builds complete, visually striking web pages.
tags: [frontend, react, ui, web]
tags: [frontend, react, animation, ui, assets, web, css, javascript]
---

## When to Use

- Building complete landing pages and marketing sites with premium UI
- Implementing cinematic scroll animations and motion systems
- Generating AI-powered media assets (images, video, audio, music)
- Writing persuasive copy for conversion-focused pages
- Setting up Tailwind, Sass, or CSS build pipelines
- Developing with SvelteKit, Next.js, Blazor, or Yew frameworks
- Building PWAs with service workers and offline support

## Do Not Use

- Backend API or server-side logic (use fullstack-dev or api-patterns)
- Mobile app development (use react-native-dev or android-native-dev)
- Document or PDF generation (use msoffice-tools or minimax-pdf)
- Database design or data modeling (use database-patterns)
- DevOps or CI/CD pipeline configuration (use ci-cd-patterns)

# Frontend Studio

Build complete, production-ready frontend pages by orchestrating 5 specialized capabilities: design engineering, motion systems, AI-generated assets, persuasive copy, and generative art.

## Skill Structure
```
frontend-dev/
├── SKILL.md                      # Core skill (this file)
├── scripts/                      # Asset generation scripts (TTS, music, video, image)
├── references/                   # Detailed guides
│   ├── minimax-cli-reference.md
│   ├── asset-prompt-guide.md
│   ├── minimax-tts-guide.md
│   ├── minimax-music-guide.md
│   ├── minimax-video-guide.md
│   ├── minimax-image-guide.md
│   ├── minimax-voice-catalog.md
│   ├── motion-recipes.md
│   ├── env-setup.md
│   ├── troubleshooting.md
│   └── ecosystem.md
├── templates/                    # Visual art templates (p5.js)
└── resources/                    # Developer tools & framework guides
    ├── tailwind.md, modern-frameworks.md, webassembly.md, pwa.md, build-tools.md
```

## Workflow — 6 Phases

### Phase 1: Design Architecture
1. Analyze request — determine page type and context
2. Set design dials (VARIANCE, MOTION_INTENSITY, VISUAL_DENSITY)
3. Plan layout sections and identify asset needs

### Phase 2: Motion Architecture
1. Select animation tools per section (see Motion Engine below)
2. Plan motion sequences following performance guardrails

### Phase 3: Asset Generation
Generate all image/video/audio assets using `scripts/`. **NEVER use placeholder URLs** (unsplash, picsum, placeholder, etc.).

1. Parse asset requirements (type, style, spec, usage)
2. Craft optimized prompts, confirm with user before generating
3. Execute via scripts, save to project — **all assets must be local files**

### Phase 4: Copywriting
Follow frameworks: **AIDA** (Attention→Interest→Desire→Action), **PAS** (Problem→Agitate→Solution), **FAB** (Feature→Advantage→Benefit).
Write real copy — no "Lorem ipsum".

### Phase 5: Build UI
Scaffold project and build sections following Design and Motion rules. All media MUST reference local assets.

### Phase 6: Quality Gates
Run final checklist below.

---

## 1. Design Engineering

### Architecture Conventions
- **Framework:** React/Next.js. Default Server Components. Interactive = `"use client"` leaf.
- **Styling:** Tailwind CSS. Check version — NEVER mix v3/v4 syntax.
- **ANTI-EMOJI POLICY:** Never emojis. Use Phosphor or Radix icons only.
- **Viewport:** `min-h-[100dvh]` not `h-screen`. CSS Grid not flex percentage math.
- **Layout:** `max-w-[1400px] mx-auto` or `max-w-7xl`.
- **Dependency check:** Verify `package.json` before importing. Output install command if missing.

### Design Rules
| Rule | Directive |
|------|-----------|
| Typography | Headlines: `text-4xl md:text-6xl tracking-tighter`. Body: `text-base leading-relaxed max-w-[65ch]`. Never Inter — use Geist/Outfit/Satoshi |
| Color | Max 1 accent, saturation < 80%. Never AI purple/blue |
| Layout | Never centered heroes when VARIANCE > 4 — force asymmetric |
| States | Always: Loading (skeleton), Empty, Error, Tactile feedback |
| Forms | Label above input, error below, `gap-2` |

### Anti-Slop Techniques
- **Liquid Glass:** `backdrop-blur` + `border-white/10` + `shadow-[inset_0_1px_0_rgba(255,255,255,0.1)]`
- **Magnetic Buttons:** `useMotionValue`/`useTransform` — never `useState` for continuous
- **Layout Transitions:** Framer `layout` + `layoutId`
- **Stagger:** `staggerChildren` or CSS `animation-delay: calc(var(--index) * 100ms)`

### Forbidden Patterns
| Category | Banned |
|----------|--------|
| Visual | Neon glows, pure black (#000), oversaturated accents, gradient text on headers |
| Typography | Inter font, Serif on dashboards |
| Layout | 3-column equal card rows, floating elements with awkward gaps |
| Components | Default shadcn/ui without customization |

### Bento Paradigm
Palette: `#f9fafb` bg, white cards `border-slate-200/50`. Surfaces: `rounded-[2.5rem]`, diffusion shadow.
5-Card Archetypes: Intelligent List, Command Input, Live Status, Wide Data Stream, Contextual UI.

### Brand Override
Dark: `#141413`, Light: `#faf9f5`, Mid: `#b0aea5`, Subtle: `#e8e6dc`
Accents: Orange `#d97757`, Blue `#6a9bcc`, Green `#788c5d`. Fonts: Poppins (headings), Lora (body).

---

## 2. Motion Engine

### Tool Selection Matrix
| Need | Tool |
|------|------|
| UI enter/exit/layout | **Framer Motion** — `AnimatePresence`, `layoutId`, springs |
| Scroll storytelling | **GSAP + ScrollTrigger** — frame-accurate |
| Looping icons | **Lottie** — lazy-load ~50KB |
| 3D/WebGL | **Three.js / R3F** — isolated `<Canvas>` |
| Hover/focus states | **CSS only** — zero JS cost |
| Native scroll-driven | **CSS** — `animation-timeline: scroll()` |

**Conflict Rules:** Never mix GSAP + Framer in same component. R3F in isolated Canvas. Lazy-load Lottie/GSAP/Three.js.

### Springs & Easings
| Feel | Framer Config | CSS Easing |
|------|---------------|------------|
| Snappy | stiffness:300, damping:30 | — |
| Smooth | stiffness:150, damping:20 | `cubic-bezier(0.16,1,0.3,1)` |
| Bouncy | stiffness:100, damping:10 | `cubic-bezier(0.34,1.56,0.64,1)` |

### Performance Rules
- **Animate only:** `transform`, `opacity`, `filter`, `clip-path`
- **Never animate:** `width`, `height`, `top`, `left`, `margin`, `padding`, `font-size`
- Perpetual animations in `React.memo` leaf components
- `will-change: transform` only during animation
- Respect `prefers-reduced-motion`, disable parallax on `pointer: coarse`
- Cap particles: desktop 800, tablet 300, mobile 100
- Every `useEffect` with GSAP must `return () => ctx.revert()`

### Animation Recipes
→ See `references/motion-recipes.md` for code snippets:
Scroll Reveal, Stagger Grid, Pinned Timeline, Tilt Card, Magnetic Button, Text Scramble, SVG Path Draw, Horizontal Scroll, Particle Background, Layout Morph

### Dependencies
```bash
npm install framer-motion           # UI (keep at top level)
npm install gsap                    # Scroll (lazy-load)
npm install lottie-react            # Icons (lazy-load)
npm install three @react-three/fiber @react-three/drei  # 3D (lazy-load)
```

---

## 3. Asset Generation

### Scripts
| Type | Script | Pattern |
|------|--------|---------|
| TTS | `scripts/minimax_tts.py` | Sync |
| Music | `scripts/minimax_music.py` | Sync |
| Video | `scripts/minimax_video.py` | Async (create→poll→download) |
| Image | `scripts/minimax_image.py` | Sync |

Env: `MINIMAX_API_KEY` (required).

### Workflow
1. **Parse:** type, quantity, style, spec, usage
2. **Craft prompt:** Be specific — composition, lighting, style. Never text in image prompts.
3. **Execute:** Show prompt to user → **must confirm before generating** → run script
4. **Save:** `<project>/public/assets/{images,videos,audio}/` as `{type}-{descriptor}-{timestamp}.{ext}`
5. **Post-process:** Images → WebP, Videos → ffmpeg compress, Audio → normalize

### Preset Shortcuts
`hero`=16:9 cinematic, `thumb`=1:1 centered, `icon`=1:1 flat, `avatar`=1:1 portrait, `banner`=21:9 OG, `bg-video`=768P 6s, `video-hd`=1080P 6s, `bgm`=30s loopable, `tts`=MiniMax HD MP3

### Detailed Guides
→ `references/minimax-cli-reference.md`, `references/asset-prompt-guide.md`, `references/minimax-voice-catalog.md`, `references/minimax-tts-guide.md`, `references/minimax-music-guide.md`, `references/minimax-video-guide.md`, `references/minimax-image-guide.md`

---

## 4. Copywriting

### Core Job
1. Grab attention → 2. Create desire → 3. Remove friction → 4. Prompt action

### Frameworks
| Framework | Structure |
|-----------|-----------|
| **AIDA** | Attention (bold headline) → Interest (elaborate problem) → Desire (transformation) → Action (CTA) |
| **PAS** | Problem → Agitate (urgency) → Solution |
| **FAB** | Feature (what it does) → Advantage (why matters) → Benefit (customer gains) |

### Headlines
Formulas: Promise ("Double open rates"), Question ("Still wasting time?"), How-To, Number ("7 mistakes"), Negative ("Stop losing"), Curiosity, Transformation ("From 50 to 500")

### CTAs
**Formula:** [Action Verb] + [What They Get] + [Urgency/Ease]
**Bad:** Submit, Click here. **Good:** "Start my free trial", "Get the template now"

### Emotional Triggers
FOMO, Fear of loss, Status, Ease, Frustration, Hope

### Objection Handling
Too expensive→Show ROI, Won't work→Social proof, No time→"10 min setup", Need to think→Scarcity

---

## 5. Visual Art

Two modes: **Static** (PDF/PNG for posters, print) and **Interactive** (HTML p5.js for generative art).

Workflow: Philosophy creation → Conceptual seed → Creation (static or interactive) → Refinement

Interactive: read `templates/viewer.html`, keep FIXED sections, replace VARIABLE sections. Seeded randomness: `randomSeed(seed); noiseSeed(seed);`

---

## Quality Gates
- [ ] Mobile layout collapse (`w-full`, `px-4`)
- [ ] `min-h-[100dvh]` not `h-screen`
- [ ] Empty, loading, error states provided
- [ ] Correct animation tool per selection matrix
- [ ] No GSAP + Framer mixed in same component
- [ ] All `useEffect` have cleanup returns
- [ ] `prefers-reduced-motion` respected
- [ ] Perpetual animations in `React.memo` leaf components
- [ ] Only GPU properties animated
- [ ] Heavy libraries lazy-loaded
- [ ] **No placeholder URLs** — grep for unsplash, picsum, placeholder, dummyimage. If found, STOP and fix.
- [ ] **All media assets exist as local files**
- [ ] Asset prompts confirmed before generation

## Ecosystem
→ See `references/ecosystem.md` for full library catalog (components, state, forms, tables, charts, animation, routing, icons, testing, color/font)

## Verification
- [ ] Dependencies verified in `package.json`
- [ ] Project compiles without errors (`npm run build`)
- [ ] All generated assets exist locally in project directory
- [ ] No placeholder URLs in any output file
- [ ] Animations respect `prefers-reduced-motion`
- [ ] Mobile layout renders properly at 375px width
- [ ] All reference links resolve
