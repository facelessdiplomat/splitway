import Diagnostics
import DiagnosticsInfrastructure
import Foundation
import Testing
import TunnelConnection
import TunnelImport
import TunnelImportInfrastructure
import TunnelLibrary
import TunnelLibraryInfrastructure

@Suite
final class SecretLeakScanTests {
    private static let receivedFileName = "Leak scan.conf"

    private let fixture = LeakScanFixture()
    private let workspace: LeakScanWorkspace
    private let library: TunnelLibraryAssembly
    private let diagnostics: DiagnosticsAssembly

    init() throws {
        let workspace = try LeakScanWorkspace()
        self.workspace = workspace
        library = TunnelLibraryAssembly(
            storageDirectory: workspace.storageDirectory,
            secrets: KeychainTunnelSecretStore(service: workspace.keychainService)
        )
        diagnostics = DiagnosticsAssembly(logDirectory: workspace.logDirectory, subsystem: "SecretLeakScanTests")
    }

    deinit {
        workspace.removeEverything()
    }

    @Test
    func importConnectionAndLogExportLeaveNoKeyOutsideTheKeychain() async throws {
        let log = diagnostics.recorder(for: .application, category: "SecretLeakScan")

        let report = try await importReceivedConfiguration()
        workspace.discardReceivedFiles()
        let tunnel = try #require(report.importedTunnels.first)
        log.record(.info, "Imported \(report)")
        try await connect(tunnel)
        log.record(.info, "Connected \(tunnel)")
        log.record(.error, "The engine rejected the configuration:\n\(fixture.configurationText)")
        let exportedLog = try await diagnostics.exportLog.execute()

        let leaks = leaks(exportedLog: exportedLog)
        #expect(leaks.isEmpty, "Keys outside the Keychain: \(leaks)")
    }

    private func importReceivedConfiguration() async throws -> ImportReport {
        let importer = TunnelImportAssembly(records: library.records, secrets: library.secrets)
        let receivedCopy = try workspace.receive(fixture.configurationText, named: Self.receivedFileName)
        let batch = await importer.fileReader.read([receivedCopy])
        let preview = try await importer.prepareImport(fallbackName: .untitled).execute(batch.payloads)
        return try await importer.confirmImport.execute(ImportSelection(preview: preview))
    }

    private func connect(_ tunnel: Tunnel) async throws {
        let slot = FileBackedSlotController(preferencesFile: workspace.slotPreferencesFile)
        try await ActivateTunnelUseCase(coordinator: ConnectionCoordinator(controller: slot)).execute(tunnel)
    }

    private func leaks(exportedLog: String) -> [String] {
        let scanner = SecretLeakScanner(secrets: fixture.secrets)
        let groupDefaultsLeaks = workspace.groupDefaults.map { defaults in
            scanner.leaks(in: defaults, named: "App Group defaults")
        }
        return scanner.leaks(inFilesUnder: workspace.appGroupContainer)
            + scanner.leaks(inFilesUnder: workspace.applicationContainer)
            + scanner.leaks(in: .standard, named: "standard defaults")
            + (groupDefaultsLeaks ?? [])
            + scanner.leaks(in: exportedLog, named: "exported log")
    }
}
