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
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1/resvg.artifactbundle.zip",
            checksum: "ddc7dce20ac220d2371254d0206b5ab94c862f2d04cfe529ab7dc67fb255c456"
        ),
        .target(
            name: "Resvg",
            dependencies: ["CResvg"],
            path: "Sources/Resvg"
        ),
    ]
)
