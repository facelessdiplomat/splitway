import AppRouting
import TunnelConfiguration
import TunnelLibrary

public struct ActiveTunnel: Sendable, Hashable {
    public let id: TunnelIdentifier
    public let configuration: TunnelConfiguration
    public let routingPolicy: RoutingPolicy
}
