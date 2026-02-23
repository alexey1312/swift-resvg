import Foundation

/// Locates a test fixture file, trying Bundle.module first (macOS/Linux),
/// then falling back to source-relative path (Windows).
///
/// Uses `#filePath` default parameter so the caller's source location is used.
func testFixtureURL(
    _ name: String,
    ext: String,
    filePath: String = #filePath
) -> URL? {
    // Try Bundle.module (works on macOS/Linux where resource bundles are supported)
    if let url = Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Fixtures") {
        return url
    }
    // Fallback: resolve relative to the caller's source file (works on Windows)
    let sourceDir = URL(fileURLWithPath: filePath).deletingLastPathComponent()
    let fileURL = sourceDir.appendingPathComponent("Fixtures").appendingPathComponent("\(name).\(ext)")
    if FileManager.default.fileExists(atPath: fileURL.path) {
        return fileURL
    }
    return nil
}
