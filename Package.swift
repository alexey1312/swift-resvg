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
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1/resvg.artifactbundle.zip",
            checksum: "d6e0743e3e8001366c337e4137ea48d47e6eaec9b38109d58452babf4a725cab"
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
