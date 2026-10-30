import AppRouting
import TunnelConfiguration
import TunnelLibrary

public enum LiveRoutingChange {
    public static func isPossible(
        from tunnel: Tunnel,
        to configuration: TunnelConfiguration?,
        routedBy policy: RoutingPolicy
    ) -> Bool {
        configuration == tunnel.configuration
            && tunnel.routingPolicy.mode.kind == .selectedApplications
            && policy.mode.kind == .selectedApplications
    }
}
