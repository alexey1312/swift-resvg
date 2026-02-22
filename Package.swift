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
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1-swift.8/resvg.artifactbundle.zip",
            checksum: "ddd90aa3f38530ac2b050bff465ee948db597f87e838d2bd4818534761418780"
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
