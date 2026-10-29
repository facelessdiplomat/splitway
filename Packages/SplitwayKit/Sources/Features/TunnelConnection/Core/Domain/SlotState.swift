import TunnelLibrary

public struct SlotState: Sendable, Hashable {
    public static let empty = SlotState(tunnelID: nil, connection: .disconnected)

    public let tunnelID: TunnelIdentifier?
    public let connection: ConnectionState

    public init(tunnelID: TunnelIdentifier?, connection: ConnectionState) {
        self.tunnelID = tunnelID
        self.connection = connection
    }

    public func connectionState(of tunnel: TunnelIdentifier) -> ConnectionState {
        tunnelID == tunnel ? connection : .disconnected
    }
}
