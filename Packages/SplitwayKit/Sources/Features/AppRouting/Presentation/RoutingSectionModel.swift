import AppRouting
import Observation

@MainActor
@Observable
public final class RoutingSectionModel {
    private static let modeOrder: [RoutingModeKind] = [.allTraffic, .selectedApplications, .selectedServices]

    public private(set) var policy: RoutingPolicy
    public let platform: RoutingPlatform

    public init(policy: RoutingPolicy, platform: RoutingPlatform) {
        self.policy = policy
        self.platform = platform
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
        policy.applicationSelection.applications.count
    }

    public var selectedServiceCount: Int {
        policy.serviceSelection.services.count
    }

    public var applicationSelection: ApplicationSelection {
        policy.applicationSelection
    }

    public var offersUnavailableTunnelChoice: Bool {
        platform == .macOS
    }

    public var blocksWhenTunnelUnavailable: Bool {
        policy.whenTunnelUnavailable == .block
    }

    public func selectMode(_ kind: RoutingModeKind) {
        guard platform.supportedModes.contains(kind) else { return }
        policy = policy.switchingMode(to: kind)
    }

    public func setBlocksWhenTunnelUnavailable(_ blocks: Bool) {
        policy = policy.replacingTunnelUnavailableBehavior(with: blocks ? .block : .bypass)
    }

    public func setApplications(_ selection: ApplicationSelection) {
        policy = policy.replacingApplicationSelection(with: selection)
    }
}
