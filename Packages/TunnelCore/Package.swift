// swift-tools-version: 6.2

import PackageDescription

let strictSwiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]

let package = Package(
    name: "TunnelCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "TunnelCoreAdapter", targets: ["TunnelCoreAdapter"])
    ],
    targets: [
        .binaryTarget(
            name: "TunnelCoreFramework",
            path: "Artifacts/TunnelCoreFramework.xcframework"
        ),
        .target(
            name: "TunnelCoreAdapter",
            dependencies: ["TunnelCoreFramework"],
            path: "Sources/TunnelCoreAdapter",
            swiftSettings: strictSwiftSettings
        ),
        .testTarget(
            name: "TunnelCoreAdapterTests",
            dependencies: ["TunnelCoreAdapter"],
            path: "Tests/TunnelCoreAdapterTests",
            swiftSettings: strictSwiftSettings
        ),
    ]
)
