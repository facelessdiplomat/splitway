import AppRouting

public struct DNSQueryRouteDecider: Sendable {
    private let matcher: ApplicationMatcher
    private let whenTunnelUnavailable: TunnelUnavailableBehavior
    private let resolvesNamesThroughTunnel: Bool

    public init(snapshot: RoutingPolicySnapshot, resolvesNamesThroughTunnel: Bool) {
        matcher = ApplicationMatcher(snapshot.applications)
        whenTunnelUnavailable = snapshot.whenTunnelUnavailable
        self.resolvesNamesThroughTunnel = resolvesNamesThroughTunnel
    }

    public func route(for source: SourceApplication, tunnel: TunnelReadiness) -> DNSQueryRoute {
        guard matcher.matches(source) else { return .toOriginalResolver }
        switch tunnel {
        case .ready:
            return resolvesNamesThroughTunnel ? .throughTunnel : .toOriginalResolver
        case .unavailable:
            return whenTunnelUnavailable == .block ? .refuse : .toOriginalResolver
        }
    }
}
