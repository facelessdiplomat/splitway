import ControlWidgets
import Shortcuts
import TunnelConnectionInfrastructure
import TunnelLibraryInfrastructure

extension TunnelControlActions {
    init(library: TunnelLibraryAssembly, connection: TunnelConnectionAssembly) {
        let shortcuts = TunnelShortcutActions(library: library, connection: connection)
        let read = ReadTunnelControlUseCase(readSlotState: connection.readSlotState, records: library.records)
        self.init(
            read: read,
            set: SetTunnelControlUseCase(read: read, connect: shortcuts.connect, disconnect: shortcuts.disconnect)
        )
    }
}
