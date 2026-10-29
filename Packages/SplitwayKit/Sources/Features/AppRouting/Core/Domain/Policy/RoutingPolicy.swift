public struct RoutingPolicy: Sendable, Hashable {
    public static let `default` = RoutingPolicy(mode: .allTraffic)

    public let mode: RoutingMode
    public let whenTunnelUnavailable: TunnelUnavailableBehavior

    public init(mode: RoutingMode, whenTunnelUnavailable: TunnelUnavailableBehavior = .block) {
        self.mode = mode
        self.whenTunnelUnavailable = whenTunnelUnavailable
    }
}
