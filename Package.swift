// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PrototypingKit",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "PrototypingKit",
            targets: ["PrototypingKit"]
        )
    ],
    targets: [
        .target(
            name: "PrototypingKit",
            path: "Sources/PrototypingKit"
        )
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
