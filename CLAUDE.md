# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the package
swift build

# Run tests
swift test

# Run a single test
swift test --filter SvgRasterizerTests/rasterizeSimpleSvg
swift test --filter TreeTraversalTests/createSvgTree

# Rebuild static libraries (requires Rust + Docker for Linux)
./Scripts/build.sh 0.45.1           # All platforms
./Scripts/build.sh 0.45.1 --macos   # macOS only
./Scripts/build.sh 0.45.1 --linux   # Linux only (via Docker)

# Rebuild Windows libraries (requires Rust on Windows)
# .\Scripts\build-windows.ps1 0.45.1
```

## Architecture

Swift bindings for [resvg](https://github.com/RazrFalcon/resvg) (Rust SVG renderer) using SE-0482 artifact bundles for static library distribution.

**Package structure:**
- `CResvg` - Binary target containing prebuilt static libraries via `resvg.artifactbundle/`
- `Resvg` - Swift wrapper target with two main APIs:
  - `SvgRasterizer` - SVG to RGBA rasterization
  - `SvgTree` - Tree traversal and inspection API

**Rasterization flow:** `SvgRasterizer.rasterize()` → parses SVG via `resvg_parse_tree_from_data` → renders to premultiplied RGBA via `resvg_render` → unpremultiplies alpha → returns `RasterizedSvg` with straight-alpha RGBA bytes.

**Tree Traversal API:**
- `SvgTree` - Owns parsed SVG, provides `root: Group` and `toSvgString()`
- `TreeNode` - Polymorphic node with `nodeType` and `as*()` casting methods
- `Group` - Container with children, transform, opacity, mask, clipPath
- `Path` - Bezier paths with segments, fill, stroke
- `Fill`/`Stroke` - Paint properties (color, gradients)
- `LinearGradient`/`RadialGradient` - Gradient definitions with stops
- `ImageNode` - Embedded images (JPEG, PNG, GIF, SVG)
- `TextNode` - Text elements with `flattened` paths

**Requirements:** Swift 6.2+ (for SE-0482), macOS 12.0+ or Linux (x86_64/aarch64) or Windows (x86_64/aarch64 MSVC)

## Gotchas

- **Git LFS required**: `.a`/`.lib` files in `resvg.artifactbundle/` are stored via Git LFS. If `swift build`/`swift test` fails with `unknown file type in libresvg.a`, run `git lfs pull`.
- **Modulemap: no `link` directive**: `module.modulemap` must NOT contain `link "resvg"`. SPM BuildPlan auto-generates `-lresvg` from the artifact bundle filename. Adding `link` in modulemap duplicates the flag and breaks Windows (lld-link doesn't add `lib` prefix).
- **Clang ignores `moduleMapPath`**: Clang auto-discovers `module.modulemap` from `headerPaths` directories, ignoring `moduleMapPath` in `info.json`. All platforms share one `include/module.modulemap`.
- **Windows linking**: Uses `.linkedLibrary("libresvg")` in Package.swift to generate `-llibresvg` → lld-link finds `libresvg.lib`. System libs (Ws2_32, Userenv, ntdll) also declared there.
- **Release branch**: `release/artifact-bundle` has its own `Package.swift` (URL-based binary target). Changes to linker settings must be applied to both.

<!-- OPENSPEC:START -->
## OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->
