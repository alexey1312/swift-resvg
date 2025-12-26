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
        // Binary target using SE-0482 artifact bundle (URL-based for SPM compatibility)
        .binaryTarget(
            name: "CResvg",
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1-swift.2/resvg.artifactbundle.zip",
            checksum: "b892a0ea23dfc316ab3388b3d95ec049e661e80b95490adf535f227383c59fe0"
        ),

        // Swift wrapper
        .target(
            name: "Resvg",
            dependencies: ["CResvg"]
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
