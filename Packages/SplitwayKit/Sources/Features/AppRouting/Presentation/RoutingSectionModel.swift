import AppRouting
import Observation

@MainActor
@Observable
public final class RoutingSectionModel {
    private static let modeOrder: [RoutingModeKind] = [.allTraffic, .selectedApplications, .selectedServices]

    public private(set) var policy: RoutingPolicy
    public let platform: RoutingPlatform
    private var applications: ApplicationSelection
    private var services: ServiceSelection

    public init(policy: RoutingPolicy, platform: RoutingPlatform) {
        self.policy = policy
        self.platform = platform
        switch policy.mode {
        case .allTraffic:
            applications = ApplicationSelection([])
            services = ServiceSelection([])
        case .selectedApplications(let selection):
            applications = selection
            services = ServiceSelection([])
        case .selectedServices(let selection):
            applications = ApplicationSelection([])
            services = selection
        }
    }

    public var availableModes: [RoutingModeKind] {
        Self.modeOrder.filter(platform.supportedModes.contains)
    }

    public var selectedMode: RoutingModeKind {
        policy.mode.kind
    }

    public var warnings: [RoutingPolicyWarning] {
        policy.warnings
    }

    public var selectedApplicationCount: Int {
        applications.applications.count
    }

    public var selectedServiceCount: Int {
        services.services.count
    }

    public var offersUnavailableTunnelChoice: Bool {
        platform == .macOS
    }

    public var blocksWhenTunnelUnavailable: Bool {
        policy.whenTunnelUnavailable == .block
    }

    public func selectMode(_ kind: RoutingModeKind) {
        guard platform.supportedModes.contains(kind) else { return }
        let mode: RoutingMode =
            switch kind {
            case .allTraffic: .allTraffic
            case .selectedApplications: .selectedApplications(applications)
            case .selectedServices: .selectedServices(services)
            }
        policy = RoutingPolicy(mode: mode, whenTunnelUnavailable: policy.whenTunnelUnavailable)
    }

    public func setBlocksWhenTunnelUnavailable(_ blocks: Bool) {
        policy = RoutingPolicy(mode: policy.mode, whenTunnelUnavailable: blocks ? .block : .bypass)
    }
}
