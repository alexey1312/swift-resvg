// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-resvg",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(name: "Resvg", targets: ["Resvg"]),
    ],
    targets: [
        // Binary target using SE-0482 artifact bundle
        // Note: Uses local path during development. Release workflow auto-updates to URL.
        .binaryTarget(
            name: "CResvg",
            path: "resvg.artifactbundle"
        ),

        // Swift wrapper
        .target(
            name: "Resvg",
            dependencies: ["CResvg"],
            linkerSettings: [
                // Workaround: SwiftPM doesn't add artifact bundle path to linker search paths on Linux
                .unsafeFlags(
                    [
                        "-L\(Context.packageDirectory)/resvg.artifactbundle/linux-x86_64",
                        "-L\(Context.packageDirectory)/resvg.artifactbundle/linux-aarch64",
                    ],
                    .when(platforms: [.linux])
                ),
            ]
        ),

        // Tests
        .testTarget(
            name: "ResvgTests",
            dependencies: ["Resvg"],
            resources: [
                .copy("Fixtures/"),
            ]
        ),
    ]
)
