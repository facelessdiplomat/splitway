import AppRouting
import TunnelLibrary

public struct TunnelRow: Identifiable, Sendable, Hashable {
    public let id: TunnelIdentifier
    public let name: String
    public let status: TunnelRowStatus
    public let routingMode: RoutingModeKind?

    public var isConnectionActive: Bool {
        status.isActive
    }

    public var canToggleConnection: Bool {
        status != .unavailable
    }

    public var canDuplicate: Bool {
        status != .unavailable
    }
}
