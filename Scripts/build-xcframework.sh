#!/bin/bash
# Build XCFramework from artifact bundle
#
# Usage:
#   ./Scripts/build-xcframework.sh
#
# Prerequisites:
#   - resvg.artifactbundle must exist (run build.sh first)
#   - Xcode command line tools
#
# Output:
#   Resvg.xcframework/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ARTIFACT_DIR="$PROJECT_ROOT/resvg.artifactbundle"
XCFRAMEWORK_DIR="$PROJECT_ROOT/Resvg.xcframework"

echo "=== Building Resvg.xcframework ==="

# Validate artifact bundle exists
if [ ! -d "$ARTIFACT_DIR" ]; then
    echo "Error: resvg.artifactbundle not found. Run build.sh first."
    exit 1
fi

if [ ! -f "$ARTIFACT_DIR/macos-universal/libresvg.a" ]; then
    echo "Error: macos-universal/libresvg.a not found in artifact bundle."
    exit 1
fi

if [ ! -d "$ARTIFACT_DIR/include" ]; then
    echo "Error: include/ directory not found in artifact bundle."
    exit 1
fi

# Clean previous build
rm -rf "$XCFRAMEWORK_DIR"

# Create XCFramework
echo "Creating XCFramework from artifact bundle..."
xcodebuild -create-xcframework \
    -library "$ARTIFACT_DIR/macos-universal/libresvg.a" \
    -headers "$ARTIFACT_DIR/include" \
    -output "$XCFRAMEWORK_DIR"

echo ""
echo "=== Done ==="
echo "Created: $XCFRAMEWORK_DIR"
echo ""
ls -la "$XCFRAMEWORK_DIR"
