import AppIntents
import Shortcuts
import TunnelConnectionInfrastructure
import TunnelLibraryInfrastructure

extension AppComposition {
    static func registeredShortcuts(
        library: TunnelLibraryAssembly,
        connection: TunnelConnectionAssembly
    ) -> TunnelShortcutActions {
        let shortcuts = TunnelShortcutActions(library: library, connection: connection)
        AppDependencyManager.shared.add(dependency: shortcuts)
        SplitwayShortcuts.updateAppShortcutParameters()
        return shortcuts
    }
}
