import TunnelConnectionInfrastructure
import TunnelEditorPresentation
import TunnelImportInfrastructure
import TunnelImportPresentation
import TunnelLibraryInfrastructure
import TunnelLibraryPresentation

@MainActor
struct AppComposition {
    static let additionMethods: [TunnelAdditionMethod] = [.importFromFile, .pasteFromClipboard, .createFromScratch]

    let tunnelList: TunnelListModel
    let statistics: TunnelStatisticsPolling
    let tunnelImport: TunnelImportModel
    let tunnelEditor: TunnelEditorFlow
    let tunnelExport: TunnelExportModel

    init(configuration: AppConfiguration) {
        let library = TunnelLibraryAssembly(storageDirectory: configuration.storageDirectory)
        let connection = TunnelConnectionAssembly(
            providerBundleIdentifier: configuration.tunnelProviderBundleIdentifier
        )
        let importer = TunnelImportAssembly(records: library.records, secrets: library.secrets)
        let tunnelList = Self.tunnelList(library: library, connection: connection)
        self.tunnelList = tunnelList
        statistics = TunnelStatisticsPolling(fetchStatistics: connection.fetchStatistics)
        tunnelExport = TunnelExportModel(exportTunnels: library.exportTunnels)
        tunnelImport = Self.tunnelImport(importer: importer, tunnelList: tunnelList)
        tunnelEditor = Self.tunnelEditor(
            library: library,
            connection: connection,
            clipboard: importer.clipboard,
            tunnelList: tunnelList
        )
    }

    func add(_ method: TunnelAdditionMethod) {
        switch method {
        case .importFromFile:
            tunnelImport.pickFiles()
        case .pasteFromClipboard:
            Task.immediate { await tunnelImport.importClipboard() }
        case .createFromScratch:
            tunnelEditor.createTunnel()
        case .scanQRCode:
            break
        }
    }

    private static func tunnelList(library: TunnelLibraryAssembly, connection: TunnelConnectionAssembly)
        -> TunnelListModel
    {
        TunnelListModel(
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

    private static func tunnelImport(importer: TunnelImportAssembly, tunnelList: TunnelListModel) -> TunnelImportModel {
        TunnelImportModel(
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

    private static func tunnelEditor(
        library: TunnelLibraryAssembly,
        connection: TunnelConnectionAssembly,
        clipboard: SystemClipboard,
        tunnelList: TunnelListModel
    ) -> TunnelEditorFlow {
        TunnelEditorFlow(
            actions: TunnelEditorActions(
                createTunnel: library.createTunnel,
                updateTunnel: library.updateTunnel,
                renameTunnel: library.renameTunnel,
                activityProbe: connection.activityProbe,
                activateTunnel: connection.activateTunnel,
                deactivateTunnel: connection.deactivateTunnel
            )
        ) { text in
            clipboard.copy(text)
        } didSave: { _ in
            await tunnelList.load()
        }
    }
}
