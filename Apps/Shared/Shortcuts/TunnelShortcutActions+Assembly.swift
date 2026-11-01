import Shortcuts
import TunnelConnectionInfrastructure
import TunnelLibraryInfrastructure

extension TunnelShortcutActions {
    init(library: TunnelLibraryAssembly, connection: TunnelConnectionAssembly) {
        let connect = ConnectTunnelShortcutUseCase(
            loadTunnels: library.loadTunnels,
            activateTunnel: connection.activateTunnel
        )
        let disconnect = DisconnectTunnelShortcutUseCase(activityProbe: connection.activityProbe)
        self.init(
            findTunnels: FindShortcutTunnelsUseCase(records: library.records),
            connect: connect,
            disconnect: disconnect,
            toggle: ToggleTunnelShortcutUseCase(
                connect: connect,
                disconnect: disconnect,
                activityProbe: connection.activityProbe
            )
        )
    }
}
