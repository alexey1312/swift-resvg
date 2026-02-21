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
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1-swift.5/Resvg.xcframework.zip",
            checksum: "60e3096a6fa01476e21543c702a0e170b5f724d0452da8d55cebed1c2479c06b"
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
