---
name: color-font-skill
description: Choose presentation-ready color palettes and font pairings for PPT/design tasks. Use when users ask for visual theme choices, brand-safe palettes, or font recommendations. Triggers include: color palette, font, PPT theme, brand colors, typography, color scheme, font pairing.
tags: [design, color, typography, ppt, branding]
---

# Color Scheme & Font Pairing Guide

## When to Use
- User asks for color palette recommendations
- User needs PPT/design theme colors
- User wants font pairing suggestions
- Brand-safe palette selection
- Accessibility-compliant color choices
- Design system token creation

## Do Not Use
- For generating actual PPTX files (use `pptx-generator` skill)
- For complex graphic design (use dedicated design tool)
- When user asks for code implementation (route to `code-builder`)

---

## 18 Universal Color Palettes (PPT Ready)

| # | Description | Colors | Vibe |
|---|-------------|--------|------|
| 1 | Calm Coastal | `#006d77` `#83c5be` `#edf6f9` `#ffddd2` `#e29578` | Warm calm |
| 2 | Bold Impact | `#2b2d42` `#8d99ae` `#edf2f4` `#ef233c` `#d90429` | High contrast |
| 3 | Nature Earth | `#606c38` `#283618` `#fefae0` `#dda15e` `#bc6c25` | Organic |
| 4 | Heritage | `#780000` `#c1121f` `#fdf0d5` `#003049` `#669bbc` | Classic |
| 5 | Soft Pastel | `#cdb4db` `#ffc8dd` `#ffafcc` `#bde0fe` `#a2d2ff` | Gentle |
| 6 | Desert | `#ccd5ae` `#e9edc9` `#fefae0` `#faedcd` `#d4a373` | Warm neutral |
| 7 | Ocean Blue | `#8ecae6` `#219ebc` `#023047` `#ffb703` `#fb8500` | Professional |
| 8 | Terracotta | `#7f5539` `#a68a64` `#ede0d4` `#656d4a` `#414833` | Earthy |
| 9 | Dark Gold | `#000814` `#001d3d` `#003566` `#ffc300` `#ffd60a` | Premium |
| 10 | Teal Coral | `#264653` `#2a9d8f` `#e9c46a` `#f4a261` `#e76f51` | Vibrant |
| 11 | Forest | `#dad7cd` `#a3b18a` `#588157` `#3a5a40` `#344e41` | Natural |
| 12 | Dusty Rose | `#edafb8` `#f7e1d7` `#dedbd2` `#b0c4b1` `#4a5759` | Muted |
| 13 | Southwest | `#335c67` `#fff3b0` `#e09f3e` `#9e2a2b` `#540b0e` | Desert |
| 14 | Elegant | `#22223b` `#4a4e69` `#9a8c98` `#c9ada7` `#f2e9e4` | Sophisticated |
| 15 | Deep Blue | `#03045e` `#0077b6` `#00b4d8` `#90e0ef` `#caf0f8` | Trust |
| 16 | Tropical | `#0081a7` `#00afb9` `#fdfcdc` `#fed9b7` `#f07167` | Energetic |
| 17 | Sunny | `#ff9f1c` `#ffbf69` `#ffffff` `#cbf3f0` `#2ec4b6` | Bright |
| 18 | Platinum Dark | `#0a0a0a` `#0070F3` `#D4AF37` `#f5f5f5` `#ffffff` | Modern |

---

## Design System Tokens (White-Gold Theme)

### White Scale
| Token | Hex | Use |
|-------|-----|-----|
| white-0 | `#ffffff` | Pure white |
| white-50 | `#fefefe` | Near white |
| white-75 | `#fcfcfc` | Slight tint |
| white-100 | `#fafafa` | Background |
| white-200 | `#f7f7f7` | Card bg |
| white-300 | `#f5f5f5` | Elevated |
| white-400 | `#f0f0f0` | Border light |
| white-500 | `#ebebeb` | Subtle border |
| white-600 | `#e5e5e5` | Border |
| white-700 | `#e0e0e0` | Divider |
| white-800 | `#d9d9d9` | Disabled |
| white-900 | `#d4d4d4` | Disabled text |
| white-1000 | `#cccccc` | Muted |

### Gold Scale
| Token | Hex | Use |
|-------|-----|-----|
| gold-25 | `#FFFDF5` | Lightest |
| gold-50 | `#FEF9E7` | Hint |
| gold-75 | `#FCF3D0` | Soft |
| gold-100 | `#FAECB8` | Hover |
| gold-200 | `#F5DC8A` | Active |
| gold-300 | `#E8C860` | Accent |
| gold-400 | `#D4AF37` | **Primary gold** |
| gold-500 | `#B8972E` | Active |
| gold-600 | `#9A7E26` | Pressed |
| gold-700 | `#7C651E` | Text on light |
| gold-800 | `#5E4C16` | Text |
| gold-900 | `#40330F` | Dark text |
| gold-1000 | `#221A08` | Deepest |

### Blue Scale
| Token | Hex | Use |
|-------|-----|-----|
| blue-25 | `#F0F7FF` | Lightest |
| blue-50 | `#E0EFFF` | Hint |
| blue-75 | `#C2DFFF` | Soft |
| blue-100 | `#A3CFFF` | Hover |
| blue-200 | `#66AFFF` | Active |
| blue-300 | `#338FFF` | Accent |
| blue-400 | `#0070F3` | **Primary blue** |
| blue-500 | `#005FCC` | Active |
| blue-600 | `#004FA6` | Pressed |
| blue-700 | `#003F80` | Text on light |
| blue-800 | `#002F5A` | Text |
| blue-900 | `#001F3D` | Dark |
| blue-1000 | `#001026` | Deepest |

### Gray Scale
| Token | Hex | Use |
|-------|-----|-----|
| gray-0 | `#ffffff` | White |
| gray-50 | `#fafafa` | Near white |
| gray-75 | `#f5f5f5` | Subtle bg |
| gray-100 | `#ededed` | bg |
| gray-200 | `#d4d4d4` | Border |
| gray-300 | `#a3a3a3` | Muted text |
| gray-400 | `#737373` | Secondary text |
| gray-500 | `#525252` | Body text |
| gray-600 | `#404040` | Strong text |
| gray-700 | `#2e2e2e` | Heading |
| gray-800 | `#1f1f1f` | Dark heading |
| gray-900 | `#141414` | Near black |
| gray-1000 | `#0a0a0a` | Pure black |

### Opacity Black
| Level | Hex | Use |
|-------|-----|-----|
| 0% | `#0a0a0a00` | Transparent |
| 2% | `#0a0a0a05` | Subtle |
| 4% | `#0a0a0a0a` | Hint |
| 8% | `#0a0a0a14` | Light overlay |
| 15% | `#0a0a0a26` | Overlay |
| 20% | `#0a0a0a33` | Divider |
| 25% | `#0a0a0a40` | Border |
| 50% | `#0a0a0a80` | Strong |
| 70% | `#0a0a0ab2` | Heavy |
| 80% | `#0a0a0acc` | Modal overlay |
| 90% | `#0a0a0ae5` | Tooltip |
| 95% | `#0a0a0af2` | Near solid |

### Opacity White
| Level | Hex | Use |
|-------|-----|-----|
| 0% | `#ffffff00` | Transparent |
| 2% | `#ffffff05` | Subtle |
| 4% | `#ffffff0a` | Hint |
| 8% | `#ffffff12` | Light overlay |
| 15% | `#ffffff26` | Overlay |
| 20% | `#ffffff33` | Divider |
| 25% | `#ffffff40` | Invert |
| 50% | `#ffffff80` | Strong |
| 70% | `#ffffffb2` | Heavy |
| 80% | `#ffffffcc` | Modal overlay |
| 90% | `#ffffffe5` | Tooltip |
| 95% | `#fffffff2` | Near solid |

---

## Font Recommendations

### Font Pairings
| Use Case | Headline | Body |
|----------|----------|------|
| Corporate PPT | Arial | Georgia, Calibri |
| Modern Web | Inter | Source Sans Pro |
| Creative | Playfair Display | Lato |
| Tech | Roboto | Open Sans |
| Academic | Merriweather | Noto Sans |

### Web Safe Font Stacks
```css
/* System UI */
font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;

/* Serif */
font-family: Georgia, 'Times New Roman', Times, serif;

/* Monospace */
font-family: 'Courier New', Courier, monospace;
```

### Font Resources
- **Google Fonts** — Largest free font library, web + download
- **Fontsource** — Self-host npm packages for all Google Fonts
- **Font Squirrel** — Curated free fonts with commercial licenses
- **Typewolf** — Typography inspiration + font reviews
- **Bunny Fonts** — Privacy-focused Google Fonts alternative

### Variable Fonts
- One file, multiple weights via axis: `wght` (weight), `wdth` (width), `ital` (italic), `slnt` (slant)
- Reduces HTTP requests: single variable font = 10+ static files
- CSS: `font-variation-settings: "wght" 375, "wdth" 85;`

### Font Loading Strategies
| Method | Best For |
|--------|----------|
| `next/font` (Next.js) | Auto-optimized, self-hosted |
| `@fontsource` | npm packages for direct import |
| `fontfaceobserver` | JS-based loading detection |
| FOUT swap | System font first, swap to custom |

### Font Subsetting (Reduce File Size)
- **glyphhanger** — Subset fonts to used characters
- **fonttools** (Python) — Programmatic subsetting
- **subfont** — Auto-subset during build pipeline

---

## Pre-built Color Systems

| System | Colors | Shades | Notes |
|--------|--------|--------|-------|
| Tailwind CSS | 22 | 11 each | Industry standard |
| Radix Colors | Accessible | Step-based | Great for UI |
| Material Palette | 19 | 10 + tone | Design system |
| Open Color | 15 | 10 each | MIT licensed |

## Contrast & Accessibility Tools
- **WebAIM Contrast Checker** — WCAG AA/AAA verification
- **Adobe Color** — Accessible palette generation
- **Accessible Color Matrix** — Test all combos at once

---

## Procedure
1. Identify context (PPT, web, brand, UI design system)
2. Select palette from 18 universal palettes or design system tokens
3. Verify contrast ratio meets WCAG AA (4.5:1 for text)
4. Pair fonts: choose complementary headline + body fonts
5. Apply consistently across all slides/pages
