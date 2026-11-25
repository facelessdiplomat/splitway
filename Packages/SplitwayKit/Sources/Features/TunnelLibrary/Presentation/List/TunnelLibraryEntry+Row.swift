import AppRouting
import TunnelConnection
import TunnelLibrary

extension TunnelLibraryEntry {
    func row(
        in slot: SlotState,
        activating pendingActivation: TunnelIdentifier?,
        naming serviceNames: [ServiceIdentifier: String]
    ) -> TunnelRow {
        switch self {
        case .readable(let tunnel):
            TunnelRow(
                id: tunnel.id,
                name: tunnel.name.description,
                status: status(of: tunnel.id, in: slot, activating: pendingActivation),
                routingMode: tunnel.routingPolicy.mode.kind,
                routedApplicationNames: tunnel.routingPolicy.mode.routedApplicationNames,
                routedServiceNames: tunnel.routingPolicy.mode.routedServiceNames(naming: serviceNames)
            )
        case .unreadable(let record):
            TunnelRow(
                id: record.id,
                name: record.name.description,
                status: .unavailable,
                routingMode: nil,
                routedApplicationNames: [],
                routedServiceNames: []
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
