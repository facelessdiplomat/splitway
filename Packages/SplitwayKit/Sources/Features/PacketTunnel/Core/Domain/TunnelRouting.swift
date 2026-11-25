import AppRouting
import TunnelEngine

public struct TunnelRouting: Sendable, Hashable {
    public let mode: RoutingModeKind
    public let networkPlan: TunnelNetworkPlan
    public let translation: ServiceRoutingTranslation?
}
