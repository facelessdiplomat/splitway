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

    var resources: [Resource]? {
        self == .presentation ? [.process("Resources")] : nil
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
    let presentationTestDependencies: [Target.Dependency]
    let layersWithoutTests: [FeatureLayer]
    let providesTestSupport: Bool

    init(
        _ name: String,
        layers: [FeatureLayer] = [.core],
        coreDependencies: [Target.Dependency] = [],
        infrastructureDependencies: [Target.Dependency] = [],
        presentationDependencies: [Target.Dependency] = [],
        testDependencies: [Target.Dependency] = [],
        infrastructureTestDependencies: [Target.Dependency] = [],
        presentationTestDependencies: [Target.Dependency] = [],
        layersWithoutTests: [FeatureLayer] = [],
        providesTestSupport: Bool = false
    ) {
        self.name = name
        self.layers = layers
        self.coreDependencies = coreDependencies
        self.infrastructureDependencies = infrastructureDependencies
        self.presentationDependencies = presentationDependencies
        self.testDependencies = testDependencies
        self.infrastructureTestDependencies = infrastructureTestDependencies
        self.presentationTestDependencies = presentationTestDependencies
        self.layersWithoutTests = layersWithoutTests
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
            + (layer == .presentation ? presentationTestDependencies : [])
        let target: Target = .target(
            name: targetName,
            dependencies: dependencies(for: layer),
            path: "Sources/Features/\(name)/\(layer.directoryName)",
            resources: layer.resources,
            swiftSettings: strictSwiftSettings
        )
        guard !layersWithoutTests.contains(layer) else { return [target] }
        return [
            target,
            .testTarget(
                name: "\(targetName)Tests",
                dependencies: layerTestDependencies,
                path: "Tests/Features/\(name)/\(layer.directoryName)Tests",
                swiftSettings: strictSwiftSettings
            ),
        ]
    }

    private var coreTargetDependency: [Target.Dependency] {
        layers.contains(.core) ? [.target(name: name)] : []
    }

    private func dependencies(for layer: FeatureLayer) -> [Target.Dependency] {
        switch layer {
        case .core: ["SharedKernel"] + coreDependencies
        case .infrastructure: coreTargetDependency + ["SharedKernel"] + infrastructureDependencies
        case .presentation: coreTargetDependency + ["SharedKernel"] + presentationDependencies
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
    FeatureModule("TunnelConfiguration", layers: [.core, .presentation], providesTestSupport: true),
    FeatureModule(
        "AppRouting",
        layers: [.core, .presentation],
        presentationDependencies: ["DesignSystemPresentation"]
    ),
    FeatureModule(
        "TunnelLibrary",
        layers: [.core, .infrastructure, .presentation],
        coreDependencies: ["TunnelConfiguration", "AppRouting"],
        infrastructureDependencies: [zipFoundation],
        presentationDependencies: [
            "TunnelConnection", "TunnelConnectionPresentation", "TunnelConfigurationPresentation",
            "AppRoutingPresentation", "DesignSystemPresentation",
        ],
        testDependencies: ["TunnelConfigurationTestSupport"],
        infrastructureTestDependencies: [zipFoundation],
        presentationTestDependencies: ["TunnelConnectionTestSupport"],
        providesTestSupport: true
    ),
    FeatureModule(
        "TunnelImport",
        layers: [.core, .infrastructure, .presentation],
        coreDependencies: ["TunnelConfiguration", "TunnelLibrary"],
        infrastructureDependencies: [zipFoundation],
        presentationDependencies: ["TunnelConfigurationPresentation", "DesignSystemPresentation"],
        testDependencies: ["TunnelConfigurationTestSupport", "TunnelLibraryTestSupport"],
        infrastructureTestDependencies: [zipFoundation, "TunnelLibraryInfrastructure"]
    ),
    FeatureModule(
        "TunnelEditor",
        layers: [.core, .presentation],
        coreDependencies: ["TunnelConfiguration", "TunnelLibrary"],
        presentationDependencies: [
            "TunnelConnection", "TunnelConfigurationPresentation", "AppRoutingPresentation", "DesignSystemPresentation",
        ],
        testDependencies: ["TunnelConfigurationTestSupport"],
        presentationTestDependencies: ["TunnelLibraryTestSupport", "TunnelConnectionTestSupport"]
    ),
    FeatureModule("Diagnostics", layers: [.core, .infrastructure]),
    FeatureModule("DesignSystem", layers: [.presentation], layersWithoutTests: [.presentation]),
    FeatureModule(
        "TunnelEngine",
        coreDependencies: ["TunnelConfiguration"],
        testDependencies: ["TunnelConfigurationTestSupport"]
    ),
    FeatureModule(
        "ProviderMessaging",
        layers: [.core, .infrastructure],
        coreDependencies: ["TunnelEngine", "AppRouting", "TunnelLibrary"],
        testDependencies: ["TunnelConfigurationTestSupport"]
    ),
    FeatureModule(
        "PacketTunnel",
        layers: [.core, .infrastructure],
        coreDependencies: ["TunnelConfiguration", "AppRouting", "TunnelEngine", "TunnelLibrary", "ProviderMessaging"],
        testDependencies: ["TunnelConfigurationTestSupport", "TunnelLibraryTestSupport"]
    ),
    FeatureModule("SystemExtension", layers: [.core, .infrastructure]),
    FeatureModule(
        "TunnelConnection",
        layers: [.core, .infrastructure, .presentation],
        coreDependencies: ["TunnelLibrary", "TunnelEngine", "ProviderMessaging"],
        infrastructureDependencies: ["ProviderMessagingInfrastructure"],
        testDependencies: ["TunnelConfigurationTestSupport"],
        providesTestSupport: true
    ),
]

let package = Package(
    name: "SplitwayKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [.library(name: "SharedKernel", targets: ["SharedKernel"])] + features.flatMap(\.products),
    dependencies: [.package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.20")],
    targets: sharedKernelTargets + features.flatMap(\.targets)
)
