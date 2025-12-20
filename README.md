# swift-resvg

Swift bindings for [resvg](https://github.com/RazrFalcon/resvg) — a high-quality SVG rendering library.

Uses [SE-0482](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0482-swiftpm-static-library-binary-target-non-apple-platforms.md) artifact bundles for cross-platform static library distribution.

## Requirements

- Swift 6.2+ (for SE-0482 artifact bundle support)
- macOS 12.0+ or Linux (x86_64/aarch64)

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/alexey1312/swift-resvg.git", branch: "release/artifact-bundle"),
]
```

Or with a specific version tag:

```swift
dependencies: [
    .package(url: "https://github.com/alexey1312/swift-resvg.git", from: "0.45.1"),
]
```

> **Note:** Use `branch: "release/artifact-bundle"` for the latest release. Version tags are created on this branch.

Then add `Resvg` to your target dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["Resvg"]
),
```

## Usage

### Rasterize SVG Data

```swift
import Resvg

let rasterizer = SvgRasterizer()

// From Data
let svgData = Data("<svg>...</svg>".utf8)
let result = try rasterizer.rasterize(data: svgData, scale: 2.0)
print("Size: \(result.width)x\(result.height)")
print("Bytes: \(result.rgba.count)") // width * height * 4 (RGBA)

// From file
let url = URL(fileURLWithPath: "/path/to/image.svg")
let result = try rasterizer.rasterize(file: url, scale: 1.0)
```

### Error Handling

```swift
do {
    let result = try rasterizer.rasterize(data: svgData)
} catch let error as ResvgError {
    print("Error: \(error.errorDescription ?? "Unknown")")
    if let suggestion = error.recoverySuggestion {
        print("Suggestion: \(suggestion)")
    }
}
```

### Output Format

`RasterizedSvg` contains:
- `width: Int` — Output width in pixels
- `height: Int` — Output height in pixels
- `rgba: [UInt8]` — Pixel data in RGBA format (straight alpha, unpremultiplied)

## Building from Source

To rebuild the static libraries:

```bash
# Build all platforms (requires Rust + Docker)
./Scripts/build.sh 0.45.1

# Build macOS only
./Scripts/build.sh 0.45.1 --macos

# Build Linux only (via Docker)
./Scripts/build.sh 0.45.1 --linux
```

## Creating a Release

To create a new release, run the workflow manually:

```bash
gh workflow run release.yml -f version=0.46.0
```

Or via GitHub UI: Actions → Release → Run workflow → enter version (without `v` prefix).

## Included Platforms

| Platform | Architecture | Library |
|----------|-------------|---------|
| macOS | arm64 + x86_64 (universal) | `resvg.artifactbundle/macos-universal/libresvg.a` |
| Linux | x86_64 | `resvg.artifactbundle/linux-x86_64/libresvg.a` |
| Linux | aarch64 | `resvg.artifactbundle/linux-aarch64/libresvg.a` |

## License

MIT — see [LICENSE](LICENSE)

resvg is licensed under Apache 2.0 or MIT.
