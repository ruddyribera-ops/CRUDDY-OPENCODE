---
name: design
description: Universal design system with variants, tweaks, and progressive sub-skills. Inspired by Huashu Design. Triggers: design a page, make a landing page, create UI, build a dashboard, style this, make it look good, redesign, landing page, web design, frontend design.
auto_load: code-builder (when UI/frontend task detected)
sub_skills:
  - design-web: web pages, landing pages, dashboards
  - design-slides: presentations, slide decks (loads pptx-generator)
  - design-infographic: infographics, data visualization
---

# Design System — Variants + Tweaks Workflow

## VARIANT-FIRST WORKFLOW (MANDATORY for any UI task)

**Never build a single design. Always generate 3 variants first.**

### Phase 1: Generate Variants

Before writing any code, produce 3 distinct visual variants:

| Variant | Vibe | When to pick |
|---------|------|-------------|
| **A — Editorial** | Clean, minimal, typographic, white space, structured | Professional, B2B, SaaS |
| **B — Atmospheric** | Dark, moody, immersive, gradient, bold | Creative, gaming, artistic |
| **C — Playful** | Colorful, rounded, friendly, illustrations | Consumer, education, community |

Each variant must have:
- One paragraph describing the visual direction
- Key color decisions (2-3 colors)
- Font choices
- A rough layout sketch (ASCII or text description)
- What makes this variant different from the others

After presenting the 3 variants, ASK: "Which variant? (A/B/C) or combine elements?"

### Phase 2: Build Chosen Variant

Once the user picks, build ONLY the chosen variant. Do not mix variants.

Apply:
1. `.opencode/design.md` rules (if present)
2. Anti-pattern checks (no glassmorphism, no purple gradients, no Inter/Geist)
3. OKLCH color system where possible

### Phase 3: Apply Tweaks

After the build, offer tweaks from the list below. The user can say:
- "dark mode" → apply dark theme
- "tighter spacing" → reduce padding/whitespace
- "change accent to green" → swap accent color
- "more breathing room" → increase spacing

---

## TWEAKS SYSTEM (Quick Changes)

After building the chosen variant, these tweaks are available. The agent recognizes natural language:

### Color Tweaks
| Command | What it does |
|---------|-------------|
| "dark mode" / "light mode" | Toggle light/dark theme |
| "change accent to [color]" | Swap accent color throughout |
| "warmer" / "cooler" | Shift color temperature |
| "higher contrast" / "lower contrast" | Adjust text/background ratio |

### Layout Tweaks
| Command | What it does |
|---------|-------------|
| "tighter" / "more breathing room" | Adjust spacing |
| "wider" / "narrower" | Adjust max content width |
| "swap hero and features" | Reorder sections |
| "add trust strip" / "remove testimonials" | Add/remove standard sections |

### Typography Tweaks
| Command | What it does |
|---------|-------------|
| "bigger headings" / "smaller headings" | Scale heading sizes |
| "serif headings" / "mono code blocks" | Change font family per role |
| "tighter line height" | Reduce line-height globally |

### Anti-Pattern Tweaks (Fix AI Slop)
| Command | What it does |
|---------|-------------|
| "less slop" | Run anti-pattern check and fix all issues |
| "kill gradients" | Remove purple/blue gradients |
| "de-glass" | Remove glassmorphism effects |
| "real fonts" | Replace Inter/Geist with alternatives |

---

## ANTI-PATTERNS (Ban These)

The agent must NEVER use these without explicit user request:
- ❌ Centered CTA button with nothing around it
- ❌ Glassmorphism / frosted glass effects
- ❌ Purple (#7c3aed) or blue (#3b82f6) as primary
- ❌ Inter or Geist fonts (too common, AI slop giveaway)
- ❌ Lucid / Heroicons defaults
- ❌ Gradient text on gradient backgrounds
- ❌ Cards with box-shadow > 0 4px 12px
- ❌ Purple-to-blue gradients

If the user asks for "modern" or "clean", do NOT default to these — that's the AI trap. Instead, ask which variant fits.

---

## PROGRESSIVE SUB-SKILLS

This skill acts as a meta-skill. Based on the task, load the matching sub-skill:

| Task | Load |
|------|------|
| Web page, landing page, dashboard | This skill (design-web) |
| Presentation, slide deck | `skills/pptx-generator/SKILL.md` |
| Infographic, data viz, chart design | `skills/frontend-design/SKILL.md` |
| Motion, animation, video | `skills/adaptive-ui/SKILL.md` |

Only load what the task needs. Don't bloat the context window.
