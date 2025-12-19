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
        .binaryTarget(
            name: "CResvg",
            path: "resvg.artifactbundle"
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
