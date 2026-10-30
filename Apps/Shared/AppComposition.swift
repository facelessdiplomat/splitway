import ApplicationCatalogPresentation
import Diagnostics
import DiagnosticsInfrastructure
import DiagnosticsPresentation
import OnboardingInfrastructure
import OnboardingPresentation
import Settings
import SettingsInfrastructure
import SettingsPresentation
import SystemExtension
import SystemExtensionPresentation
import TunnelConnectionInfrastructure
import TunnelEditorPresentation
import TunnelImportInfrastructure
import TunnelImportPresentation
import TunnelLibraryInfrastructure
import TunnelLibraryPresentation

#if os(macOS)
    import ApplicationCatalogInfrastructure
    import SystemExtensionInfrastructure
#endif

@MainActor
struct AppComposition {
    static var additionMethods: [TunnelAdditionMethod] {
        #if os(iOS)
            [.importFromFile, .scanQRCode, .pasteFromClipboard, .createFromScratch]
        #else
            [.importFromFile, .pasteFromClipboard, .createFromScratch]
        #endif
    }

    let tunnelList: TunnelListModel
    let statistics: TunnelStatisticsPolling
    let tunnelImport: TunnelImportModel
    let tunnelEditor: TunnelEditorFlow
    let tunnelExport: TunnelExportModel
    let logViewer: LogViewerPresenter
    let settings: SettingsPresenter
    let onboarding: OnboardingModel
    let reportCollector: MetricKitReportCollector

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
        let diagnostics = DiagnosticsAssembly(
            logDirectory: configuration.logDirectory,
            subsystem: configuration.logSubsystem
        )
        logViewer = Self.logViewer(diagnostics: diagnostics, configuration: configuration)
        reportCollector = diagnostics.reportCollector
        reportCollector.start()
        onboarding = Self.onboarding(configuration: configuration)
        settings = Self.settings(
            version: AppVersion(marketingVersion: configuration.version, build: configuration.build))
        diagnostics.recorder(for: .application, category: "App").record(
            .info, "Splitway \(configuration.version) started")
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
            tunnelImport.scanQRCode()
        }
    }

    private static func logViewer(diagnostics: DiagnosticsAssembly, configuration: AppConfiguration)
        -> LogViewerPresenter
    {
        LogViewerPresenter(
            model: LogViewerModel(
                actions: LogViewerActions(
                    loadEntries: diagnostics.loadLogEntries,
                    clearLog: diagnostics.clearLog,
                    exportLog: diagnostics.exportLog,
                    prepareCrashReport: diagnostics.prepareCrashReport(
                        environment: CrashReportEnvironment(
                            application: "Splitway \(configuration.version) (\(configuration.build))",
                            system: configuration.systemDescription
                        )
                    )
                )
            )
        )
    }

    private static func onboarding(configuration: AppConfiguration) -> OnboardingModel {
        OnboardingModel(
            record: UserDefaultsOnboardingRecord(),
            systemExtension: systemExtensionWizard(configuration: configuration)
        )
    }

    private static func systemExtensionWizard(configuration: AppConfiguration) -> SystemExtensionWizardModel? {
        #if os(macOS)
            SystemExtensionWizardModel(
                activate: EnsureSystemExtensionActivatedUseCase(
                    activator: OSSystemExtensionActivator(
                        extensionIdentifier: configuration.tunnelProviderBundleIdentifier)
                )
            )
        #else
            nil
        #endif
    }

    private static func settings(version: AppVersion) -> SettingsPresenter {
        SettingsPresenter(
            version: version,
            notices: ThirdPartyNoticesModel(loadNotices: SettingsAssembly().loadThirdPartyNotices)
        )
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
                prepareImport: importer.prepareImport(fallbackNames: TunnelImportModel.fallbackNames),
                confirmImport: importer.confirmImport,
                fileReader: importer.fileReader,
                clipboard: importer.clipboard,
                cameraAccess: importer.cameraAccess,
                qrCodeDecoder: importer.qrCodeDecoder
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
            ),
            applicationPicker: applicationPicker
        ) { text in
            clipboard.copy(text)
        } didSave: { _ in
            await tunnelList.load()
        }
    }

    private static var applicationPicker: ApplicationPickerActions? {
        #if os(macOS)
            let catalog = ApplicationCatalogAssembly()
            return ApplicationPickerActions(
                loadApplications: catalog.loadInstalledApplications,
                resolveIdentity: catalog.resolveApplicationIdentity,
                fileReader: catalog.fileReader,
                iconLoader: catalog.iconLoader
            )
        #else
            return nil
        #endif
    }
}
