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
    let testDependencies: [Target.Dependency]
    let infrastructureTestDependencies: [Target.Dependency]
    let providesTestSupport: Bool

    init(
        _ name: String,
        layers: [FeatureLayer] = [.core],
        coreDependencies: [Target.Dependency] = [],
        infrastructureDependencies: [Target.Dependency] = [],
        presentationDependencies: [Target.Dependency] = [],
        testDependencies: [Target.Dependency] = [],
        infrastructureTestDependencies: [Target.Dependency] = [],
        providesTestSupport: Bool = false
    ) {
        self.name = name
        self.layers = layers
        self.coreDependencies = coreDependencies
        self.infrastructureDependencies = infrastructureDependencies
        self.presentationDependencies = presentationDependencies
        self.testDependencies = testDependencies
        self.infrastructureTestDependencies = infrastructureTestDependencies
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
        let layerTestDependencies: [Target.Dependency] =
            [.target(name: targetName), "SharedKernelTestSupport"]
            + (providesTestSupport ? [.target(name: testSupportName)] : [])
            + testDependencies
            + (layer == .infrastructure ? infrastructureTestDependencies : [])
        return [
            .target(
                name: targetName,
                dependencies: dependencies(for: layer),
                path: "Sources/Features/\(name)/\(layer.directoryName)",
                swiftSettings: strictSwiftSettings
            ),
            .testTarget(
                name: "\(targetName)Tests",
                dependencies: layerTestDependencies,
                path: "Tests/Features/\(name)/\(layer.directoryName)Tests",
                swiftSettings: strictSwiftSettings
            ),
        ]
    }

    private func dependencies(for layer: FeatureLayer) -> [Target.Dependency] {
        switch layer {
        case .core: ["SharedKernel"] + coreDependencies
        case .infrastructure: [.target(name: name), "SharedKernel"] + infrastructureDependencies
        case .presentation: [.target(name: name), "SharedKernel"] + presentationDependencies
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

let zipFoundation: Target.Dependency = .product(name: "ZIPFoundation", package: "ZIPFoundation")

let features: [FeatureModule] = [
    FeatureModule("TunnelConfiguration", providesTestSupport: true),
    FeatureModule("AppRouting"),
    FeatureModule(
        "TunnelLibrary",
        layers: [.core, .infrastructure],
        coreDependencies: ["TunnelConfiguration", "AppRouting"],
        infrastructureDependencies: [zipFoundation],
        testDependencies: ["TunnelConfigurationTestSupport"],
        infrastructureTestDependencies: [zipFoundation],
        providesTestSupport: true
    ),
    FeatureModule(
        "TunnelImport",
        layers: [.core, .infrastructure],
        infrastructureDependencies: [zipFoundation],
        infrastructureTestDependencies: [zipFoundation]
    ),
]

let package = Package(
    name: "SplitwayKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "SharedKernel", targets: ["SharedKernel"])] + features.flatMap(\.products),
    dependencies: [.package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.20")],
    targets: sharedKernelTargets + features.flatMap(\.targets)
)
