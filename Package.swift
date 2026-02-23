// swift-tools-version: 5.9
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
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1-swift.11/Resvg.xcframework.zip",
            checksum: "fd8e35dde2441511079d46b142e60663a416d2865b32b4828c180bbd7859f739"
        ),
        .target(
            name: "Resvg",
            dependencies: ["CResvg"],
            path: "Sources/Resvg",
            linkerSettings: [
                .linkedLibrary("iconv", .when(platforms: [.macOS])),
            ]
        ),
    ]
)
