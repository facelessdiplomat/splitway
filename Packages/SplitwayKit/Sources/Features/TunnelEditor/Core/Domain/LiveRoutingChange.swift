import AppRouting
import TunnelConfiguration
import TunnelLibrary

public enum LiveRoutingChange {
    private static let modesChangingLive: Set<RoutingModeKind> = [.selectedApplications]

    public static func isPossible(
        from tunnel: Tunnel,
        to configuration: TunnelConfiguration?,
        routedBy policy: RoutingPolicy
    ) -> Bool {
        configuration == tunnel.configuration
            && tunnel.routingPolicy.mode.kind == policy.mode.kind
            && modesChangingLive.contains(policy.mode.kind)
    }
}
