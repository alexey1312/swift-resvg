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
        .binaryTarget(
            name: "CResvg",
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1-swift.6/resvg.artifactbundle.zip",
            checksum: "5b091cfa404eec91261536a6da0731442c4b02f291e7c8abddc6f3d028b601bf"
        ),
        .target(
            name: "Resvg",
            dependencies: ["CResvg"],
            path: "Sources/Resvg",
            linkerSettings: [
                // Windows system libraries required by Rust std
                .linkedLibrary("Ws2_32", .when(platforms: [.windows])),
                .linkedLibrary("Userenv", .when(platforms: [.windows])),
                .linkedLibrary("ntdll", .when(platforms: [.windows])),
            ]
        ),
    ]
)
