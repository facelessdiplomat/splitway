import AppRouting
import TunnelConnection
import TunnelLibrary

extension TunnelLibraryEntry {
    func row(
        in slot: SlotState,
        activating pendingActivation: TunnelIdentifier?
    ) -> TunnelRow {
        switch self {
        case .readable(let tunnel):
            TunnelRow(
                id: tunnel.id,
                name: tunnel.name.description,
                status: status(of: tunnel.id, in: slot, activating: pendingActivation),
                routingMode: tunnel.routingPolicy.mode.kind,
                routedApplicationNames: tunnel.routingPolicy.mode.routedApplicationNames
            )
        case .unreadable(let record):
            TunnelRow(
                id: record.id,
                name: record.name.description,
                status: .unavailable,
                routingMode: nil,
                routedApplicationNames: []
            )
        }
    }

    private func status(
        of id: TunnelIdentifier,
        in slot: SlotState,
        activating pendingActivation: TunnelIdentifier?
    ) -> TunnelRowStatus {
        let connection = slot.connectionState(of: id)
        guard id == pendingActivation, !connection.isActive else { return TunnelRowStatus(connection) }
        return .connecting
    }
}
