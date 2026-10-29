import AppRouting
import TunnelLibrary

public struct TunnelProviderConfiguration: Sendable, Hashable, Codable {
    public let tunnelID: TunnelIdentifier
    public let routingPolicy: RoutingPolicy

    public init(tunnelID: TunnelIdentifier, routingPolicy: RoutingPolicy) {
        self.tunnelID = tunnelID
        self.routingPolicy = routingPolicy
    }
}
