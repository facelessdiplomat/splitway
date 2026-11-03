import AppRouting
import TunnelConfiguration

public struct PlanTunnelRoutingUseCase: Sendable {
    public init() {}

    public func execute(
        configuration: TunnelConfiguration,
        policy: RoutingPolicy
    ) throws(PacketTunnelError) -> TunnelRouting {
        do {
            return TunnelRouting(
                mode: policy.mode.kind,
                networkPlan: try TunnelNetworkPlanner.plan(for: configuration, routedBy: policy)
            )
        } catch {
            throw .invalidNetworkPlan(error)
        }
    }
}
