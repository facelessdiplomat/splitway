import SharedKernel

public struct RoutingPolicySnapshot: Sendable, Hashable {
    public let applications: [ApplicationIdentity]
    public let tunnelNetworks: IPNetworkSet
    public let whenTunnelUnavailable: TunnelUnavailableBehavior

    public init(
        applications: [ApplicationIdentity],
        tunnelNetworks: IPNetworkSet,
        whenTunnelUnavailable: TunnelUnavailableBehavior
    ) {
        self.applications = applications
        self.tunnelNetworks = tunnelNetworks
        self.whenTunnelUnavailable = whenTunnelUnavailable
    }

    public init?(policy: RoutingPolicy, tunnelNetworks: IPNetworkSet) {
        guard case .selectedApplications(let selection) = policy.mode else { return nil }
        self.init(
            applications: selection.applications,
            tunnelNetworks: tunnelNetworks,
            whenTunnelUnavailable: policy.whenTunnelUnavailable
        )
    }
}
