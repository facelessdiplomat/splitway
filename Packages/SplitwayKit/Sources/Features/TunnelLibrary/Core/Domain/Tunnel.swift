import AppRouting
import TunnelConfiguration

public struct Tunnel: Sendable, Hashable, Identifiable {
    public let id: TunnelIdentifier
    public let name: TunnelName
    public let configuration: TunnelConfiguration
    public let routingPolicy: RoutingPolicy

    public init(
        id: TunnelIdentifier = TunnelIdentifier(),
        name: TunnelName,
        configuration: TunnelConfiguration,
        routingPolicy: RoutingPolicy = .default
    ) {
        self.id = id
        self.name = name
        self.configuration = configuration
        self.routingPolicy = routingPolicy
    }

    public func renamed(to name: TunnelName) -> Tunnel {
        Tunnel(id: id, name: name, configuration: configuration, routingPolicy: routingPolicy)
    }

    public func reconfigured(with configuration: TunnelConfiguration) -> Tunnel {
        Tunnel(id: id, name: name, configuration: configuration, routingPolicy: routingPolicy)
    }

    public func routed(by routingPolicy: RoutingPolicy) -> Tunnel {
        Tunnel(id: id, name: name, configuration: configuration, routingPolicy: routingPolicy)
    }
}
