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
    var layers: [FeatureLayer] = [.core]
    var coreDependencies: [Target.Dependency] = []
    var infrastructureDependencies: [Target.Dependency] = []
    var presentationDependencies: [Target.Dependency] = []
    var testDependencies: [Target.Dependency] = []
    var infrastructureTestDependencies: [Target.Dependency] = []
    var presentationTestDependencies: [Target.Dependency] = []
    var infrastructureResources: [Resource]?
    var layersWithoutTests: [FeatureLayer] = []
    var providesTestSupport = false

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
            resources: layer == .infrastructure ? infrastructureResources : layer.resources,
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
    FeatureModule(
        name: "TunnelConfiguration",
        layers: [.core, .presentation],
        presentationDependencies: ["DesignSystemPresentation"],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "AppRouting",
        layers: [.core, .presentation],
        presentationDependencies: ["DesignSystemPresentation"],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "TunnelLibrary",
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
        name: "TunnelImport",
        layers: [.core, .infrastructure, .presentation],
        coreDependencies: ["TunnelConfiguration", "TunnelLibrary"],
        infrastructureDependencies: [zipFoundation],
        presentationDependencies: ["TunnelConfigurationPresentation", "DesignSystemPresentation"],
        testDependencies: ["TunnelConfigurationTestSupport", "TunnelLibraryTestSupport"],
        infrastructureTestDependencies: [zipFoundation, "TunnelLibraryInfrastructure"]
    ),
    FeatureModule(
        name: "TunnelEditor",
        layers: [.core, .presentation],
        coreDependencies: ["AppRouting", "TunnelConfiguration", "TunnelLibrary"],
        presentationDependencies: [
            "TunnelConnection", "TunnelConfigurationPresentation", "AppRoutingPresentation",
            "ApplicationCatalogPresentation", "DesignSystemPresentation",
        ],
        testDependencies: ["TunnelConfigurationTestSupport"],
        presentationTestDependencies: [
            "TunnelLibraryTestSupport", "TunnelConnectionTestSupport", "ApplicationCatalogTestSupport",
        ]
    ),
    FeatureModule(
        name: "Diagnostics",
        layers: [.core, .infrastructure, .presentation],
        infrastructureDependencies: [zipFoundation],
        presentationDependencies: ["DesignSystemPresentation"],
        infrastructureTestDependencies: [zipFoundation],
        providesTestSupport: true
    ),
    FeatureModule(name: "DesignSystem", layers: [.presentation], layersWithoutTests: [.presentation]),
    FeatureModule(
        name: "ApplicationCatalog",
        layers: [.core, .infrastructure, .presentation],
        coreDependencies: ["AppRouting"],
        presentationDependencies: ["DesignSystemPresentation"],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "Settings",
        layers: [.core, .infrastructure, .presentation],
        presentationDependencies: ["DesignSystemPresentation"],
        infrastructureResources: [.process("Resources")],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "TunnelEngine",
        coreDependencies: ["TunnelConfiguration"],
        testDependencies: ["TunnelConfigurationTestSupport"],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "ProviderMessaging",
        layers: [.core, .infrastructure],
        coreDependencies: ["TunnelEngine", "AppRouting", "TunnelLibrary"],
        testDependencies: ["TunnelConfigurationTestSupport"]
    ),
    FeatureModule(
        name: "PacketTunnel",
        layers: [.core, .infrastructure],
        coreDependencies: ["TunnelConfiguration", "AppRouting", "TunnelEngine", "TunnelLibrary", "ProviderMessaging"],
        testDependencies: ["TunnelConfigurationTestSupport", "TunnelLibraryTestSupport"]
    ),
    FeatureModule(
        name: "TransparentProxy",
        layers: [.core, .infrastructure],
        coreDependencies: [
            "TunnelConfiguration", "AppRouting", "TunnelEngine", "PacketTunnel", "DNSProxy", "ProviderMessaging",
        ],
        testDependencies: [
            "TunnelConfigurationTestSupport", "AppRoutingTestSupport", "TunnelEngineTestSupport", "DNSProxyTestSupport",
        ],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "DNSProxy",
        coreDependencies: ["TunnelConfiguration"],
        testDependencies: ["TunnelConfigurationTestSupport"],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "SecretDelivery",
        layers: [.core, .infrastructure],
        coreDependencies: ["TunnelLibrary", "TunnelConnection"],
        testDependencies: [
            "TunnelLibraryTestSupport", "TunnelConfigurationTestSupport", "TunnelConnectionTestSupport",
        ],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "SystemExtension",
        layers: [.core, .infrastructure, .presentation],
        presentationDependencies: ["DesignSystemPresentation"],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "Onboarding",
        layers: [.core, .infrastructure, .presentation],
        presentationDependencies: ["SystemExtension", "SystemExtensionPresentation", "DesignSystemPresentation"],
        presentationTestDependencies: ["SystemExtensionTestSupport"],
        layersWithoutTests: [.core],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "TunnelConnection",
        layers: [.core, .infrastructure, .presentation],
        coreDependencies: ["AppRouting", "TunnelLibrary", "TunnelEngine", "ProviderMessaging"],
        infrastructureDependencies: ["ProviderMessagingInfrastructure"],
        testDependencies: ["TunnelConfigurationTestSupport"],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "ServiceCatalog",
        layers: [.core, .infrastructure],
        coreDependencies: ["AppRouting"],
        infrastructureResources: [.process("Resources")],
        providesTestSupport: true
    ),
    FeatureModule(
        name: "Shortcuts",
        coreDependencies: ["TunnelLibrary", "TunnelConnection"],
        testDependencies: ["TunnelLibraryTestSupport", "TunnelConnectionTestSupport", "TunnelConfigurationTestSupport"]
    ),
    FeatureModule(
        name: "MenuBar",
        layers: [.core, .infrastructure, .presentation],
        presentationDependencies: [
            "TunnelLibrary", "TunnelLibraryPresentation", "TunnelConnection", "AppRoutingPresentation",
            "DesignSystemPresentation",
        ],
        presentationTestDependencies: [
            "TunnelLibrary", "TunnelLibraryPresentation", "TunnelLibraryTestSupport", "TunnelConnection",
            "TunnelConnectionTestSupport", "TunnelConfiguration", "TunnelConfigurationTestSupport", "AppRouting",
        ],
        infrastructureResources: [.process("Resources")],
        layersWithoutTests: [.core, .infrastructure]
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
