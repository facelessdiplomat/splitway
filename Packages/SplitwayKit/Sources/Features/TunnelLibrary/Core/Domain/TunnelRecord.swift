import AppRouting

public struct TunnelRecord: Sendable, Hashable, Codable {
    public let id: TunnelIdentifier
    public let name: TunnelName
    public let routingPolicy: RoutingPolicy

    public init(id: TunnelIdentifier, name: TunnelName, routingPolicy: RoutingPolicy) {
        self.id = id
        self.name = name
        self.routingPolicy = routingPolicy
    }

    init(_ tunnel: Tunnel) {
        self.init(id: tunnel.id, name: tunnel.name, routingPolicy: tunnel.routingPolicy)
    }
}
