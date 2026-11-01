public struct TunnelShortcutActions: Sendable {
    public let findTunnels: FindShortcutTunnelsUseCase
    public let connect: ConnectTunnelShortcutUseCase
    public let disconnect: DisconnectTunnelShortcutUseCase
    public let toggle: ToggleTunnelShortcutUseCase

    public init(
        findTunnels: FindShortcutTunnelsUseCase,
        connect: ConnectTunnelShortcutUseCase,
        disconnect: DisconnectTunnelShortcutUseCase,
        toggle: ToggleTunnelShortcutUseCase
    ) {
        self.findTunnels = findTunnels
        self.connect = connect
        self.disconnect = disconnect
        self.toggle = toggle
    }
}
