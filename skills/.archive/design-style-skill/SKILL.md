---
name: design-style-skill
description: Visual style recipes for PPT presentations — defines style, radius, spacing, and layout rules for cohesive slide design.
tags: [design, ui, ppt, style]
---

# Style Recipes — Visual Design Guidelines for Presentations

## When to Use
- Choose design style for a PPT or presentation
- Define visual style, radius, spacing, and layout
- Select cohesive design language for slides
- Apply consistent styling across a deck

## Do Not Use
- Generate actual PPTX files (use pptx-generator)
- Choose color palettes (use color-font-skill)
- Implement CSS/HTML styling
- Create design system tokens

同一套设计可通过调整圆角和间距呈现4种不同风格。根据场景选择合适的风格配方。

> **单位说明**: PptxGenJS 使用英寸(inch)作为单位。幻灯片尺寸为 10" × 5.625" (LAYOUT_16x9)

## 风格概览

| 风格 | 圆角范围 | 间距范围 | 适合场景 |
|---|---|---|---|
| **Sharp & Compact** | 0 ~ 0.05" | 紧凑 | 数据密集型、表格、专业报告 |
| **Soft & Balanced** | 0.08" ~ 0.12" | 适中 | 企业汇报、商务演示、通用PPT |
| **Rounded & Spacious** | 0.15" ~ 0.25" | 宽松 | 产品介绍、营销演示、创意展示 |
| **Pill & Airy** | 0.3" ~ 0.5" | 通透 | 品牌展示、发布会、高端演示 |

详细 Token 配方见 `references/tokens.md`，组件级映射见 `references/component-mapping.md`。

## 混搭原则

### 1. 外层容器 ≥ 内层圆角
```
// 正确：外 > 内
card:   rectRadius: 0.2
button: rectRadius: 0.1

// 错误：内 > 外 → 视觉溢出感
card:   rectRadius: 0.1
button: rectRadius: 0.2
```

### 2. 信息密度决定间距
| 区域类型 | 推荐风格 |
|---|---|
| 数据显示区 | Sharp / Soft（紧凑间距） |
| 内容浏览区 | Rounded / Pill（宽松间距） |
| 标题区域 | Soft / Rounded（适中间距） |

### 3. 圆角与元素高度的关系
圆角不应超过元素高度的一半。详见 `references/specs.md`。

## 快速选择指南

| 演示类型 | 推荐风格 | 原因 |
|---|---|---|
| 财务/数据报告 | Sharp & Compact | 信息密度高，专业严谨 |
| 企业汇报/商务 | Soft & Balanced | 平衡专业与友好 |
| 产品介绍/营销 | Rounded & Spacious | 现代感，亲切感 |
| 发布会/品牌展示 | Pill & Airy | 高端感，视觉冲击 |
| 培训/教育 | Soft / Rounded | 清晰易读，友好 |
| 技术分享 | Sharp / Soft | 专业，信息清晰 |

## Verification
- [ ] One style chosen and applied consistently across all slides
- [ ] Radius values consistent per component type
- [ ] Spacing follows chosen style's ranges
- [ ] Mixing principles respected (outer ≥ inner radius)
- [ ] Font sizes follow the typography scale
- [ ] Color contrast meets accessibility standards

See `references/tokens.md`, `references/component-mapping.md`, `references/specs.md` for complete design system.
