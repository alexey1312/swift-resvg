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
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1-swift.9/Resvg.xcframework.zip",
            checksum: "761d1bbe5d21d050896132c1d6b9186f4c98db769ca47aa52ecf9e3381362735"
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
