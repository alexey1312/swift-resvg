// swift-tools-version: 6.0
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
        .binaryTarget(
            name: "CResvg",
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1-swift.3/resvg.artifactbundle.zip",
            checksum: "7aaf1e3c103bb0c8371e0f38f7f21a5e2f3d2d7a5025aff5754f069f43ec3797"
        ),
        .target(
            name: "Resvg",
            dependencies: ["CResvg"],
            path: "Sources/Resvg"
        ),
    ]
)
