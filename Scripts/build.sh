#!/bin/bash
# Build resvg static libraries for all platforms and create artifact bundle
#
# Usage:
#   ./Scripts/build.sh                    # Build current version (0.45.1)
#   ./Scripts/build.sh 0.46.0             # Build specific version
#   ./Scripts/build.sh 0.46.0 --linux     # Build Linux only (in container)
#   ./Scripts/build.sh 0.46.0 --macos     # Build macOS only
#
# Requirements:
#   macOS: Rust toolchain (rustup target add aarch64-apple-darwin x86_64-apple-darwin)
#   Linux: Docker (for cross-compilation)
#
# Outputs:
#   resvg.artifactbundle/
#   ├── info.json
#   ├── include/resvg.h
#   ├── include/module.modulemap
#   ├── macos-universal/libresvg.a
#   ├── linux-x86_64/libresvg.a
#   └── linux-aarch64/libresvg.a

set -euo pipefail

RESVG_VERSION="${1:-0.45.1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/.resvg-build"
BUNDLE_DIR="$PROJECT_ROOT/resvg.artifactbundle"

# Parse optional flags
BUILD_LINUX=true
BUILD_MACOS=true
if [[ "${2:-}" == "--linux" ]]; then
    BUILD_MACOS=false
elif [[ "${2:-}" == "--macos" ]]; then
    BUILD_LINUX=false
fi

echo "=== Building resvg $RESVG_VERSION artifact bundle ==="

# Clean and clone resvg
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
echo "Cloning resvg v$RESVG_VERSION..."
git clone --depth 1 --branch "v$RESVG_VERSION" \
    https://github.com/RazrFalcon/resvg.git "$BUILD_DIR/resvg"

# Create artifact bundle structure
mkdir -p "$BUNDLE_DIR/include"
mkdir -p "$BUNDLE_DIR/macos-universal"
mkdir -p "$BUNDLE_DIR/linux-x86_64"
mkdir -p "$BUNDLE_DIR/linux-aarch64"

# Copy header
cp "$BUILD_DIR/resvg/crates/c-api/resvg.h" "$BUNDLE_DIR/include/"

# Create module map
cat > "$BUNDLE_DIR/include/module.modulemap" << 'EOF'
module CResvg {
    header "resvg.h"
    link "resvg"
    export *
}
EOF

#######################################
# macOS Build (Universal Binary)
#######################################
if $BUILD_MACOS; then
    echo ""
    echo "=== Building macOS universal binary ==="

    # Ensure Rust targets are installed
    rustup target add aarch64-apple-darwin x86_64-apple-darwin 2>/dev/null || true

    cd "$BUILD_DIR/resvg/crates/c-api"

    echo "Building for arm64..."
    cargo build --release --target aarch64-apple-darwin

    echo "Building for x86_64..."
    cargo build --release --target x86_64-apple-darwin

    echo "Creating universal static library..."
    lipo -create \
        "$BUILD_DIR/resvg/target/aarch64-apple-darwin/release/libresvg.a" \
        "$BUILD_DIR/resvg/target/x86_64-apple-darwin/release/libresvg.a" \
        -output "$BUNDLE_DIR/macos-universal/libresvg.a"

    echo "macOS library: $(file "$BUNDLE_DIR/macos-universal/libresvg.a")"
fi

#######################################
# Linux Build (using Docker)
#######################################
if $BUILD_LINUX; then
    echo ""
    echo "=== Building Linux libraries (via Docker) ==="

    # Create simple Dockerfile for native builds
    cat > "$BUILD_DIR/Dockerfile.linux" << 'DOCKERFILE'
FROM rust:1.83-slim-bookworm
WORKDIR /build
DOCKERFILE

    # Build x86_64 using platform emulation (more reliable than cross-compilation)
    echo "Building for Linux x86_64..."
    mkdir -p "$BUILD_DIR/target-x86_64"
    docker build --platform linux/amd64 -t resvg-linux-amd64 -f "$BUILD_DIR/Dockerfile.linux" "$BUILD_DIR"
    docker run --rm --platform linux/amd64 \
        -v "$BUILD_DIR/resvg:/build" \
        -v "$BUILD_DIR/target-x86_64:/build/target" \
        resvg-linux-amd64 \
        bash -c "cd crates/c-api && cargo build --release"

    cp "$BUILD_DIR/target-x86_64/release/libresvg.a" \
       "$BUNDLE_DIR/linux-x86_64/"

    # Build aarch64 using platform emulation
    echo "Building for Linux aarch64..."
    mkdir -p "$BUILD_DIR/target-aarch64"
    docker build --platform linux/arm64 -t resvg-linux-arm64 -f "$BUILD_DIR/Dockerfile.linux" "$BUILD_DIR"
    docker run --rm --platform linux/arm64 \
        -v "$BUILD_DIR/resvg:/build" \
        -v "$BUILD_DIR/target-aarch64:/build/target" \
        resvg-linux-arm64 \
        bash -c "cd crates/c-api && cargo build --release"

    cp "$BUILD_DIR/target-aarch64/release/libresvg.a" \
       "$BUNDLE_DIR/linux-aarch64/"

    echo "Linux x86_64 library: $(file "$BUNDLE_DIR/linux-x86_64/libresvg.a")"
    echo "Linux aarch64 library: $(file "$BUNDLE_DIR/linux-aarch64/libresvg.a")"
fi

#######################################
# Generate info.json
#######################################
echo ""
echo "=== Generating artifact bundle manifest ==="

cat > "$BUNDLE_DIR/info.json" << EOF
{
    "schemaVersion": "1.0",
    "artifacts": {
        "CResvg": {
            "type": "staticLibrary",
            "version": "$RESVG_VERSION",
            "variants": [
                {
                    "path": "macos-universal/libresvg.a",
                    "supportedTriples": [
                        "arm64-apple-macosx",
                        "x86_64-apple-macosx"
                    ],
                    "staticLibraryMetadata": {
                        "headerPaths": ["include"],
                        "moduleMapPath": "include/module.modulemap",
                        "linkedLibraries": ["iconv"]
                    }
                },
                {
                    "path": "linux-x86_64/libresvg.a",
                    "supportedTriples": ["x86_64-unknown-linux-gnu"],
                    "staticLibraryMetadata": {
                        "headerPaths": ["include"],
                        "moduleMapPath": "include/module.modulemap"
                    }
                },
                {
                    "path": "linux-aarch64/libresvg.a",
                    "supportedTriples": ["aarch64-unknown-linux-gnu"],
                    "staticLibraryMetadata": {
                        "headerPaths": ["include"],
                        "moduleMapPath": "include/module.modulemap"
                    }
                }
            ]
        }
    }
}
EOF

# Clean up build directory
rm -rf "$BUILD_DIR"

echo ""
echo "=== Done ==="
echo "Artifact bundle created: $BUNDLE_DIR"
echo ""
echo "Contents:"
find "$BUNDLE_DIR" -type f -exec ls -lh {} \;
echo ""
echo "Header version:"
grep "RESVG_VERSION" "$BUNDLE_DIR/include/resvg.h" | head -1
