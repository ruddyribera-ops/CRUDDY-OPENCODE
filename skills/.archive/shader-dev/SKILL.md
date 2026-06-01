---
name: shader-dev
description: Comprehensive GLSL shader techniques — ray marching, SDF modeling, fluid simulation, particle systems, procedural generation, lighting, post-processing.
tags: [graphics, shader, glsl, webgl]
---

## When to Use
- Writing GLSL shaders for real-time visual effects
- Ray marching and SDF modeling
- Particle systems, fluid simulations, procedural generation
- Post-processing pipelines and lighting models
- ShaderToy-compatible demos and experiments

## Do Not Use
- CPU-based rendering or software rasterization
- Game engine scripting (use Unity, Unreal Engine, Godot)
- UI layout or 2D canvas (use CSS, SVG, Canvas2D)

# Shader Craft — 36 GLSL Techniques

## Skill Structure
```
shader-dev/
├── SKILL.md                      # Core skill (this file)
├── techniques/                   # Implementation guides (read per routing table)
│   ├── ray-marching.md
│   ├── sdf-3d.md
│   ├── lighting-model.md
│   ├── procedural-noise.md
│   └── ... (32 more)
└── reference/                    # Extended theory & math derivations
    └── ... (matching set)
```

## How to Use
1. Identify technique(s) from routing table below matching the user's request
2. Read relevant file from `techniques/` — core principles, implementation steps, code templates
3. For deeper understanding, follow reference links to `reference/` files
4. Apply WebGL2 Adaptation Rules when generating standalone HTML

## Technique Routing Table (Quick Selection)

| User wants... | Primary technique |
|---|---|
| 3D objects/scenes from math | `ray-marching` + `sdf-3d` + `lighting-model` |
| Organic/warped shapes | `domain-warping` + `procedural-noise` |
| Fluid/smoke/ink | `fluid-simulation` + `multipass-buffer` |
| Particles (fire, sparks, snow) | `particle-system` + `procedural-noise` |
| Ocean/water surface | `water-ocean` + `atmospheric-scattering` |
| Terrain/landscape | `terrain-rendering` + `procedural-noise` |
| Clouds/fog/fire | `volumetric-rendering` + `procedural-noise` |
| Realistic lighting | `lighting-model` + `shadow-techniques` |
| Path tracing / GI | `path-tracing-gi` + `multipass-buffer` |
| Voxel worlds | `voxel-rendering` + `lighting-model` |
| Noise/FBM textures | `procedural-noise` |
| Voronoi/cell patterns | `voronoi-cellular-noise` |
| Fractals (Mandelbrot, Julia) | `fractal-rendering` |
| Bloom/glitch/tone mapping | `post-processing` + `multipass-buffer` |
| 2D shapes/UI from SDF | `sdf-2d` + `color-palette` |
| Procedural audio | `sound-synthesis` |
| Debugging errors | `webgl-pitfalls` |

→ Full 36-technique routing table in `techniques/` index.

## Technique Index by Category
- **Geometry & SDF:** sdf-2d, sdf-3d, csg-boolean-operations, domain-repetition, domain-warping, sdf-tricks
- **Ray Casting & Lighting:** ray-marching, analytic-ray-tracing, path-tracing-gi, lighting-model, shadow-techniques, ambient-occlusion, normal-estimation
- **Simulation:** fluid-simulation, simulation-physics, particle-system, cellular-automata
- **Natural Phenomena:** water-ocean, terrain-rendering, atmospheric-scattering, volumetric-rendering
- **Procedural:** procedural-noise, procedural-2d-pattern, voronoi-cellular-noise, fractal-rendering, color-palette
- **Post-Processing:** post-processing, multipass-buffer, texture-sampling, matrix-transform, polar-uv-manipulation, anti-aliasing, camera-effects, texture-mapping-advanced
- **Audio:** sound-synthesis
- **Debugging:** webgl-pitfalls

## WebGL2 Adaptation Rules
When generating standalone HTML from ShaderToy GLSL:
- Use `canvas.getContext("webgl2")`, `#version 300 es`, `precision highp float;`
- `fragCoord` → `gl_FragCoord.xy`, `gl_FragColor` → `fragColor` (declared as `out vec4 fragColor;`)
- Wrap `void mainImage(...)` inside `void main() { mainImage(fragColor, gl_FragCoord.xy); }`
- Declare functions before use (GLSL requirement)
- `#define` cannot use function calls — use `const` instead
- Implement ShaderToy uniforms: `iTime`, `iResolution`, `iMouse`, `iFrame`

## HTML Page Setup
- Canvas fills viewport, auto-resizes: `body { margin: 0; overflow: hidden; background: #000; }`
- `let`/`const` variables at top of `<script>` (before any function using them — TDZ)

## Performance Budget
- Ray marching main loop: ≤ 128 steps
- Volume sampling: ≤ 32 steps
- FBM octaves: ≤ 6 layers
- Total nested loop iterations/pixel: ≤ 1000

## Shader Debugging
| Check | Code | What to look for |
|-------|------|------------------|
| Surface normals | `col = nor * 0.5 + 0.5;` | Smooth gradients = correct |
| Ray march steps | `col = vec3(float(steps)/float(MAX_STEPS));` | Red = bottleneck |
| SDF distance | `col = vec3(t / MAX_DIST);` | Verify hit distances |
| UV coordinates | `col = vec3(uv, 0.0);` | Check coordinate mapping |

## Resources
- Shadertoy (shadertoy.com), The Book of Shaders (thebookofshaders.com)
- GLSL editors: vscode-glsl, glsl-canvas
- Frameworks: Three.js, regl, PixiJS, Babylon.js, WGPU
- Learning: Inigo Quilez (iquilezles.org)

## Verification
- [ ] Shader compiles without WebGL2 errors (check browser console)
- [ ] Canvas renders expected visual output
- [ ] All uniforms initialized (iTime, iResolution, iMouse, iFrame)
- [ ] Performance stays within budget limits
- [ ] Mobile/tablet doesn't crash (reduce steps for low-end GPU)
- [ ] All reference links resolve
