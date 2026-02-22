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
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1-swift.9/resvg.artifactbundle.zip",
            checksum: "620dfc1b2e86ff3725ab1ca29c5626672d06f69119e467c07c4af9ee057e51bb"
        ),
        .target(
            name: "Resvg",
            dependencies: ["CResvg"],
            path: "Sources/Resvg",
            linkerSettings: [
                // Windows: link libresvg.lib explicitly — SPM copies libresvg.lib from artifact bundle,
                // but the modulemap omits `link "resvg"` to avoid duplicate flags
                .linkedLibrary("libresvg", .when(platforms: [.windows])),
                // Windows system libraries required by Rust std
                .linkedLibrary("Ws2_32", .when(platforms: [.windows])),
                .linkedLibrary("Userenv", .when(platforms: [.windows])),
                .linkedLibrary("ntdll", .when(platforms: [.windows])),
            ]
        ),
    ]
)
