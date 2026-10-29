import AppRouting
import SharedKernel

public enum TunnelNetworkPlanError: Error, Equatable, Sendable {
    case routingModeNotSupported(RoutingModeKind)
    case missingInterfaceAddress(IPAddressFamily)
}
