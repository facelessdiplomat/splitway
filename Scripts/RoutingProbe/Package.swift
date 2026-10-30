// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [.enableUpcomingFeature("ExistentialAny")]

let package = Package(
    name: "RoutingProbe",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "RoutingProbeCore", swiftSettings: swiftSettings),
        .executableTarget(name: "RoutingProbe", dependencies: ["RoutingProbeCore"], swiftSettings: swiftSettings),
        .testTarget(name: "RoutingProbeCoreTests", dependencies: ["RoutingProbeCore"], swiftSettings: swiftSettings),
    ]
)
