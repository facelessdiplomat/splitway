import TunnelConnectionInfrastructure
import TunnelImportInfrastructure
import TunnelImportPresentation
import TunnelLibraryInfrastructure
import TunnelLibraryPresentation

@MainActor
struct AppComposition {
    static let additionMethods: [TunnelAdditionMethod] = [.importFromFile, .pasteFromClipboard]

    let tunnelList: TunnelListModel
    let statistics: TunnelStatisticsPolling
    let tunnelImport: TunnelImportModel

    init(configuration: AppConfiguration) {
        let library = TunnelLibraryAssembly(storageDirectory: configuration.storageDirectory)
        let connection = TunnelConnectionAssembly(
            providerBundleIdentifier: configuration.tunnelProviderBundleIdentifier
        )
        let importer = TunnelImportAssembly(records: library.records, secrets: library.secrets)
        let tunnelList = TunnelListModel(
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
        self.tunnelList = tunnelList
        statistics = TunnelStatisticsPolling(fetchStatistics: connection.fetchStatistics)
        tunnelImport = TunnelImportModel(
            actions: TunnelImportActions(
                prepareImport: importer.prepareImport(fallbackName: TunnelImportModel.pastedTunnelName),
                confirmImport: importer.confirmImport,
                fileReader: importer.fileReader,
                clipboard: importer.clipboard
            )
        ) {
            await tunnelList.load()
        }
    }

    func add(_ method: TunnelAdditionMethod) {
        switch method {
        case .importFromFile:
            tunnelImport.pickFiles()
        case .pasteFromClipboard:
            Task.immediate { await tunnelImport.importClipboard() }
        case .scanQRCode, .createFromScratch:
            break
        }
    }
}
