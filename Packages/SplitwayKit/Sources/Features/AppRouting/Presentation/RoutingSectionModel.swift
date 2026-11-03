import AppRouting
import Observation

@MainActor
@Observable
public final class RoutingSectionModel {
    public private(set) var policy: RoutingPolicy

    public init(policy: RoutingPolicy) {
        self.policy = policy
    }

    public var availableModes: [RoutingModeKind] {
        RoutingModeKind.allCases
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

    public var applicationSelection: ApplicationSelection {
        policy.applicationSelection
    }

    public var blocksWhenTunnelUnavailable: Bool {
        policy.whenTunnelUnavailable == .block
    }

    public func selectMode(_ kind: RoutingModeKind) {
        policy = policy.switchingMode(to: kind)
    }

    public func setBlocksWhenTunnelUnavailable(_ blocks: Bool) {
        policy = policy.replacingTunnelUnavailableBehavior(with: blocks ? .block : .bypass)
    }

    public func setApplications(_ selection: ApplicationSelection) {
        policy = policy.replacingApplicationSelection(with: selection)
    }
}
