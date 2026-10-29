// swift-tools-version: 6.2

import PackageDescription

let strictSwiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]

enum FeatureLayer {
    case core
    case infrastructure
    case presentation

    func targetName(for feature: String) -> String {
        switch self {
        case .core: feature
        case .infrastructure: "\(feature)Infrastructure"
        case .presentation: "\(feature)Presentation"
        }
    }

    var directoryName: String {
        switch self {
        case .core: "Core"
        case .infrastructure: "Infrastructure"
        case .presentation: "Presentation"
        }
    }
}

struct FeatureModule {
    let name: String
    let layers: [FeatureLayer]
    let coreDependencies: [Target.Dependency]
    let infrastructureDependencies: [Target.Dependency]
    let presentationDependencies: [Target.Dependency]
    let providesTestSupport: Bool

    init(
        _ name: String,
        layers: [FeatureLayer] = [.core],
        coreDependencies: [Target.Dependency] = [],
        infrastructureDependencies: [Target.Dependency] = [],
        presentationDependencies: [Target.Dependency] = [],
        providesTestSupport: Bool = false
    ) {
        self.name = name
        self.layers = layers
        self.coreDependencies = coreDependencies
        self.infrastructureDependencies = infrastructureDependencies
        self.presentationDependencies = presentationDependencies
        self.providesTestSupport = providesTestSupport
    }

    var targets: [Target] {
        layers.flatMap(targets(for:)) + testSupportTargets
    }

    var products: [Product] {
        layers.map { layer in
            let targetName = layer.targetName(for: name)
            return .library(name: targetName, targets: [targetName])
        }
    }

    private var testSupportName: String {
        "\(name)TestSupport"
    }

    private var testSupportTargets: [Target] {
        guard providesTestSupport else { return [] }
        return [
            .target(
                name: testSupportName,
                dependencies: [.target(name: name), "SharedKernelTestSupport"],
                path: "Tests/Features/\(name)/TestSupport",
                swiftSettings: strictSwiftSettings
            )
        ]
    }

    private func targets(for layer: FeatureLayer) -> [Target] {
        let targetName = layer.targetName(for: name)
        let testDependencies: [Target.Dependency] =
            [.target(name: targetName), "SharedKernelTestSupport"]
            + (providesTestSupport ? [.target(name: testSupportName)] : [])
        return [
            .target(
                name: targetName,
                dependencies: dependencies(for: layer),
                path: "Sources/Features/\(name)/\(layer.directoryName)",
                swiftSettings: strictSwiftSettings
            ),
            .testTarget(
                name: "\(targetName)Tests",
                dependencies: testDependencies,
                path: "Tests/Features/\(name)/\(layer.directoryName)Tests",
                swiftSettings: strictSwiftSettings
            ),
        ]
    }

    private func dependencies(for layer: FeatureLayer) -> [Target.Dependency] {
        switch layer {
        case .core: ["SharedKernel"] + coreDependencies
        case .infrastructure: [.target(name: name)] + infrastructureDependencies
        case .presentation: [.target(name: name)] + presentationDependencies
        }
    }
}

let sharedKernelTargets: [Target] = [
    .target(
        name: "SharedKernel",
        path: "Sources/SharedKernel",
        swiftSettings: strictSwiftSettings
    ),
    .target(
        name: "SharedKernelTestSupport",
        dependencies: ["SharedKernel"],
        path: "Tests/SharedKernelTestSupport",
        swiftSettings: strictSwiftSettings
    ),
    .testTarget(
        name: "SharedKernelTests",
        dependencies: ["SharedKernel", "SharedKernelTestSupport"],
        path: "Tests/SharedKernelTests",
        swiftSettings: strictSwiftSettings
    ),
]

let features: [FeatureModule] = [
    FeatureModule("TunnelConfiguration", providesTestSupport: true),
    FeatureModule("AppRouting"),
]

let package = Package(
    name: "SplitwayKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "SharedKernel", targets: ["SharedKernel"])] + features.flatMap(\.products),
    targets: sharedKernelTargets + features.flatMap(\.targets)
)
