import TunnelConnection
import TunnelLibrary

extension TunnelLibraryEntry {
    func row(in slot: SlotState) -> TunnelRow {
        switch self {
        case .readable(let tunnel):
            TunnelRow(
                id: tunnel.id,
                name: tunnel.name.description,
                status: TunnelRowStatus(slot.connectionState(of: tunnel.id)),
                routingMode: tunnel.routingPolicy.mode.kind
            )
        case .unreadable(let record):
            TunnelRow(id: record.id, name: record.name.description, status: .unavailable, routingMode: nil)
        }
    }
}
