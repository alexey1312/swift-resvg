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

# Rebuild static libraries (requires Rust + Docker for Linux)
./Scripts/build.sh 0.45.1           # All platforms
./Scripts/build.sh 0.45.1 --macos   # macOS only
./Scripts/build.sh 0.45.1 --linux   # Linux only (via Docker)
```

## Architecture

Swift bindings for [resvg](https://github.com/RazrFalcon/resvg) (Rust SVG renderer) using SE-0482 artifact bundles for static library distribution.

**Package structure:**
- `CResvg` - Binary target containing prebuilt static libraries via `resvg.artifactbundle/`
- `Resvg` - Swift wrapper target exposing `SvgRasterizer` and `ResvgError`

**Key flow:** `SvgRasterizer.rasterize()` → parses SVG via `resvg_parse_tree_from_data` → renders to premultiplied RGBA via `resvg_render` → unpremultiplies alpha → returns `RasterizedSvg` with straight-alpha RGBA bytes.

**Requirements:** Swift 6.2+ (for SE-0482), macOS 12.0+ or Linux (x86_64/aarch64)

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
