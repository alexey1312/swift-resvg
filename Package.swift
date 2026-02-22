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
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1-swift.10/resvg.artifactbundle.zip",
            checksum: "0e397dbb0398dfbab669ef4a4709535fe9db4ddae6eff10c8bad5be0fe274d92"
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
