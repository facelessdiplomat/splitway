import TunnelLibrary
import TunnelLibraryPresentation

public struct MenuBarTunnel: Identifiable, Sendable, Hashable {
    public let id: TunnelIdentifier
    public let name: String
    public let isActive: Bool
    public let isSelectable: Bool

    init(row: TunnelRow) {
        id = row.id
        name = row.name
        isActive = row.isConnectionActive
        isSelectable = row.canToggleConnection
    }
}
