import AppIntents
import ControlWidgets
import Diagnostics
import DiagnosticsInfrastructure
import Shortcuts
import TunnelConnectionInfrastructure
import TunnelLibraryInfrastructure

struct ControlsComposition: Sendable {
    private static let logCategory = "Controls"

    private let configuration: AppConfiguration

    init(configuration: AppConfiguration) {
        self.configuration = configuration
    }

    func registerDependencies() {
        let shortcuts = TunnelShortcutActions(library: library, connection: connection)
        AppDependencyManager.shared.add(dependency: shortcuts)
        AppDependencyManager.shared.add(dependency: self)
    }

    func tunnelControl() -> TunnelControlActions {
        TunnelControlActions(library: library, connection: connection)
    }

    var log: LogRecorder {
        DiagnosticsAssembly(logDirectory: configuration.logDirectory, subsystem: configuration.logSubsystem)
            .recorder(for: .application, category: Self.logCategory)
    }

    private var library: TunnelLibraryAssembly {
        TunnelLibraryAssembly(storageDirectory: configuration.storageDirectory)
    }

    private var connection: TunnelConnectionAssembly {
        TunnelConnectionAssembly(providerBundleIdentifier: configuration.tunnelProviderBundleIdentifier)
    }
}
