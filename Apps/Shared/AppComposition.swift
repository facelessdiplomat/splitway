import TunnelConnectionInfrastructure
import TunnelLibraryInfrastructure
import TunnelLibraryPresentation

@MainActor
struct AppComposition {
    let tunnelList: TunnelListModel

    init(configuration: AppConfiguration) {
        let library = TunnelLibraryAssembly(storageDirectory: configuration.storageDirectory)
        let connection = TunnelConnectionAssembly(
            providerBundleIdentifier: configuration.tunnelProviderBundleIdentifier
        )
        tunnelList = TunnelListModel(
            library: TunnelLibraryActions(
                loadTunnels: library.loadTunnels,
                deleteTunnel: library.deleteTunnel(stoppingActiveTunnelWith: connection.activityProbe),
                duplicateTunnel: library.duplicateTunnel,
                reorderTunnels: library.reorderTunnels
            ),
            connection: TunnelConnectionActions(
                activateTunnel: connection.activateTunnel,
                deactivateTunnel: connection.deactivateTunnel,
                observeConnection: connection.observeConnection
            )
        )
    }
}
