import SharedKernel

public struct FlowRoutingDecider: Sendable {
    private let matcher: ApplicationMatcher
    private let tunnelNetworks: IPNetworkSet
    private let whenTunnelUnavailable: TunnelUnavailableBehavior

    public init(snapshot: RoutingPolicySnapshot) {
        matcher = ApplicationMatcher(snapshot.applications)
        tunnelNetworks = snapshot.tunnelNetworks
        whenTunnelUnavailable = snapshot.whenTunnelUnavailable
    }

    public func decision(for flow: FlowDescriptor, tunnel: TunnelReadiness) -> FlowRouteDecision {
        guard matcher.matches(flow.source) else { return .direct }
        let address: IPAddress?
        if case .address(let destinationAddress) = flow.destination {
            guard tunnelNetworks.contains(destinationAddress) else { return .direct }
            address = destinationAddress
        } else {
            address = nil
        }
        switch tunnel {
        case .unavailable:
            return whenTunnelUnavailable == .block ? .block : .direct
        case .ready(let carriesIPv6):
            return address?.family == .ipv6 && !carriesIPv6 ? .block : .tunnel
        }
    }
}
