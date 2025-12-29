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
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1-swift.3/Resvg.xcframework.zip",
            checksum: "2f1deba53d6a20fd51bbf417582fa9b9efd31aa4b7aeedfa9e28267909b7ac78"
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
