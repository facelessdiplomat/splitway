import ApplicationCatalogInfrastructure
import ApplicationCatalogPresentation
import Diagnostics
import DiagnosticsInfrastructure
import DiagnosticsPresentation
import OnboardingInfrastructure
import OnboardingPresentation
import Settings
import SettingsInfrastructure
import SettingsPresentation
import Shortcuts
import SystemExtension
import SystemExtensionInfrastructure
import SystemExtensionPresentation
import TunnelConnectionInfrastructure
import TunnelEditorPresentation
import TunnelImportInfrastructure
import TunnelImportPresentation
import TunnelLibraryInfrastructure
import TunnelLibraryPresentation

@MainActor
struct AppComposition {
    static var additionMethods: [TunnelAdditionMethod] {
        [.importFromFile, .pasteFromClipboard, .createFromScratch]
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
    let shortcuts: TunnelShortcutActions

    init(configuration: AppConfiguration) {
        let diagnostics = DiagnosticsAssembly(
            logDirectory: configuration.logDirectory,
            subsystem: configuration.logSubsystem
        )
        let services = AppTunnelServices(
            configuration: configuration,
            log: diagnostics.recorder(for: .application, category: "Secrets")
        )
        let (library, connection) = (services.library, services.connection)
        shortcuts = Self.registeredShortcuts(library: library, connection: connection)
        let importer = TunnelImportAssembly(records: library.records, secrets: library.secrets)
        let tunnelList = Self.tunnelList(services: services)
        self.tunnelList = tunnelList
        statistics = TunnelStatisticsPolling(fetchStatistics: connection.fetchStatistics)
        tunnelExport = TunnelExportModel(exportTunnels: library.exportTunnels, abandonedCopies: TemporaryExportCopies())
        logViewer = Self.logViewer(diagnostics: diagnostics, configuration: configuration)
        reportCollector = diagnostics.reportCollector
        reportCollector.start()
        onboarding = Self.onboarding(configuration: configuration)
        settings = Self.settings(
            version: AppVersion(marketingVersion: configuration.version, build: configuration.build),
            uninstall: Self.uninstall(configuration: configuration, services: services)
        )
        diagnostics.recorder(for: .application, category: "App").record(
            .info, "Splitway \(configuration.version) started")
        tunnelImport = Self.tunnelImport(importer: importer, tunnelList: tunnelList)
        tunnelEditor = Self.tunnelEditor(services: services, clipboard: importer.clipboard, tunnelList: tunnelList)
    }

    func add(_ method: TunnelAdditionMethod) {
        switch method {
        case .importFromFile:
            tunnelImport.pickFiles()
        case .pasteFromClipboard:
            Task.immediate { await tunnelImport.importClipboard() }
        case .createFromScratch:
            tunnelEditor.createTunnel()
        }
    }

    func paste(_ texts: [String]) {
        Task.immediate { await tunnelImport.importPastedTexts(texts) }
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
                ),
                abandonedCopies: TemporaryExportCopies()
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
        SystemExtensionWizardModel(
            activate: EnsureSystemExtensionActivatedUseCase(
                activator: OSSystemExtensionActivator(
                    extensionIdentifier: configuration.tunnelProviderBundleIdentifier)
            )
        )
    }

    private static func settings(version: AppVersion, uninstall: UninstallModel?) -> SettingsPresenter {
        SettingsPresenter(
            version: version,
            notices: ThirdPartyNoticesModel(loadNotices: SettingsAssembly().loadThirdPartyNotices),
            loginItem: loginItem,
            uninstall: uninstall
        )
    }

    private static func uninstall(configuration: AppConfiguration, services: AppTunnelServices) -> UninstallModel? {
        AppUninstall.model(configuration: configuration, services: services)
    }

    private static var loginItem: LoginItemModel? {
        LoginItemModel(loginItem: MainAppLoginItem())
    }

    private static func tunnelList(services: AppTunnelServices) -> TunnelListModel {
        let (library, connection) = (services.library, services.connection)
        return TunnelListModel(
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
                prepareImport: importer.prepareImport(fallbackName: TunnelImportModel.fallbackName),
                confirmImport: importer.confirmImport,
                fileReader: importer.fileReader,
                clipboard: importer.clipboard
            )
        ) {
            await tunnelList.load()
        }
    }

    private static func tunnelEditor(
        services: AppTunnelServices,
        clipboard: SystemClipboard,
        tunnelList: TunnelListModel
    ) -> TunnelEditorFlow {
        let (library, connection) = (services.library, services.connection)
        return TunnelEditorFlow(
            actions: TunnelEditorActions(
                createTunnel: library.createTunnel,
                updateTunnel: library.updateTunnel,
                renameTunnel: library.renameTunnel,
                activityProbe: connection.activityProbe,
                activateTunnel: connection.activateTunnel,
                deactivateTunnel: connection.deactivateTunnel,
                applyRoutingPolicy: connection.applyRoutingPolicy
            ),
            applicationPicker: applicationPicker
        ) { text in
            clipboard.copy(text)
        } didSave: { _ in
            await tunnelList.load()
        }
    }

    private static var applicationPicker: ApplicationPickerActions? {
        let catalog = ApplicationCatalogAssembly()
        return ApplicationPickerActions(
            loadApplications: catalog.loadInstalledApplications,
            resolveIdentity: catalog.resolveApplicationIdentity,
            fileReader: catalog.fileReader,
            fileAccess: catalog.fileAccess,
            iconLoader: catalog.iconLoader
        )
    }
}
