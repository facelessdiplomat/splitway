import TunnelLibrary

public struct ToggleTunnelShortcutUseCase: Sendable {
    private let connect: ConnectTunnelShortcutUseCase
    private let disconnect: DisconnectTunnelShortcutUseCase
    private let activityProbe: any TunnelActivityProbe

    public init(
        connect: ConnectTunnelShortcutUseCase,
        disconnect: DisconnectTunnelShortcutUseCase,
        activityProbe: any TunnelActivityProbe
    ) {
        self.connect = connect
        self.disconnect = disconnect
        self.activityProbe = activityProbe
    }

    public func execute(_ identifier: TunnelIdentifier) async throws(TunnelShortcutError) -> TunnelShortcutOutcome {
        if await activityProbe.isActive(identifier) {
            try await disconnect.execute(identifier)
            return .disconnected
        }
        try await connect.execute(identifier)
        return .connected
    }
}
