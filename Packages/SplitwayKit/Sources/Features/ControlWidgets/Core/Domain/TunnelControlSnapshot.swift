import TunnelConnection
import TunnelLibrary

public struct TunnelControlSnapshot: Sendable, Hashable {
    public let selection: TunnelIdentifier?
    public let slot: SlotState
    public let records: [TunnelRecord]

    public init(selection: TunnelIdentifier?, slot: SlotState, records: [TunnelRecord]) {
        self.selection = selection
        self.slot = slot
        self.records = records
    }

    public var targetTunnel: TunnelIdentifier? {
        selection ?? installedTunnelInLibrary ?? records.first?.id
    }

    public var value: TunnelControlValue {
        let target = targetTunnel
        return TunnelControlValue(
            isOn: target != nil && target == slot.tunnelID && slot.connection.isActive,
            tunnelName: records.first { record in record.id == target }?.name.description
        )
    }

    private var installedTunnelInLibrary: TunnelIdentifier? {
        records.first { record in record.id == slot.tunnelID }?.id
    }
}
