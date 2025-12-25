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

#######################################
# Apply patch: Add SVG export functions
#######################################
echo ""
echo "=== Applying SVG export patch ==="

# Add new functions to lib.rs
cat >> "$BUILD_DIR/resvg/crates/c-api/lib.rs" << 'RUST_PATCH'

// =============================================================================
// SVG Export Functions (added by swift-resvg)
// =============================================================================

use std::ffi::CString;

/// Exports the render tree back to normalized SVG string.
///
/// The SVG is normalized by usvg with all defaults applied:
/// - Missing fill defaults to black
/// - CSS styles are resolved
/// - `<use>` references are expanded
/// - clip-path elements are resolved
///
/// Returns NULL on error. Must be freed via `resvg_svg_string_destroy`.
#[no_mangle]
pub extern "C" fn resvg_tree_to_svg(
    tree: *const resvg_render_tree,
    len: *mut usize,
) -> *mut std::os::raw::c_char {
    if tree.is_null() || len.is_null() {
        return std::ptr::null_mut();
    }

    let tree = unsafe { &*tree };
    let svg_string = tree.0.to_string(&usvg::WriteOptions::default());

    unsafe { *len = svg_string.len(); }

    match CString::new(svg_string) {
        Ok(cstr) => cstr.into_raw(),
        Err(_) => std::ptr::null_mut(),
    }
}

/// Frees SVG string allocated by `resvg_tree_to_svg`.
#[no_mangle]
pub extern "C" fn resvg_svg_string_destroy(svg: *mut std::os::raw::c_char) {
    if !svg.is_null() {
        unsafe { let _ = CString::from_raw(svg); }
    }
}
RUST_PATCH

echo "Rust patch applied successfully"

# Create artifact bundle structure
mkdir -p "$BUNDLE_DIR/include"
mkdir -p "$BUNDLE_DIR/macos-universal"
mkdir -p "$BUNDLE_DIR/linux-x86_64"
mkdir -p "$BUNDLE_DIR/linux-aarch64"

# Copy header
cp "$BUILD_DIR/resvg/crates/c-api/resvg.h" "$BUNDLE_DIR/include/"

# Patch header with SVG export function declarations
cat >> "$BUNDLE_DIR/include/resvg.h.tmp" << 'HEADER_PATCH'

/**
 * @brief Exports the parsed tree back to normalized SVG string.
 *
 * The SVG is normalized by usvg with all defaults applied:
 * - Missing fill defaults to black
 * - CSS styles are resolved
 * - `<use>` references are expanded
 * - clip-path elements are resolved
 *
 * @param tree Render tree.
 * @param len Output: length of the returned string (excluding null terminator).
 * @return Normalized SVG string. NULL on error. Must be freed via resvg_svg_string_destroy.
 */
char* resvg_tree_to_svg(const resvg_render_tree *tree, uintptr_t *len);

/**
 * @brief Frees SVG string allocated by resvg_tree_to_svg.
 */
void resvg_svg_string_destroy(char *svg);

HEADER_PATCH

# Insert before #ifdef __cplusplus
sed -i '' 's/#ifdef __cplusplus//' "$BUNDLE_DIR/include/resvg.h"
cat "$BUNDLE_DIR/include/resvg.h.tmp" >> "$BUNDLE_DIR/include/resvg.h"
echo "#ifdef __cplusplus" >> "$BUNDLE_DIR/include/resvg.h"
echo "} // extern \"C\"" >> "$BUNDLE_DIR/include/resvg.h"
echo "#endif // __cplusplus" >> "$BUNDLE_DIR/include/resvg.h"
echo "" >> "$BUNDLE_DIR/include/resvg.h"
echo "#endif /* RESVG_H */" >> "$BUNDLE_DIR/include/resvg.h"
rm "$BUNDLE_DIR/include/resvg.h.tmp"
# Remove duplicate end markers
sed -i '' '/^} \/\/ extern "C"$/d' "$BUNDLE_DIR/include/resvg.h"
sed -i '' '/#endif \/\/ __cplusplus/d' "$BUNDLE_DIR/include/resvg.h"
sed -i '' '/#endif \/\* RESVG_H \*\//d' "$BUNDLE_DIR/include/resvg.h"
# Add them back once
echo "" >> "$BUNDLE_DIR/include/resvg.h"
echo "#ifdef __cplusplus" >> "$BUNDLE_DIR/include/resvg.h"
echo "} // extern \"C\"" >> "$BUNDLE_DIR/include/resvg.h"
echo "#endif // __cplusplus" >> "$BUNDLE_DIR/include/resvg.h"
echo "" >> "$BUNDLE_DIR/include/resvg.h"
echo "#endif /* RESVG_H */" >> "$BUNDLE_DIR/include/resvg.h"

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
