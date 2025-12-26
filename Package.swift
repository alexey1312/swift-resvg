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
            url: "https://github.com/alexey1312/swift-resvg/releases/download/v0.45.1-swift.2/resvg.artifactbundle.zip",
            checksum: "c45c095bfde3f4a04434fcfa5e250aadcd4c1c30307d069cd97daaf65f43a4aa"
        ),
        .target(
            name: "Resvg",
            dependencies: ["CResvg"],
            path: "Sources/Resvg"
        ),
    ]
)
