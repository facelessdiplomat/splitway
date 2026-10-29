import Foundation
import Testing
import TunnelConfigurationTestSupport
import TunnelImport

@Suite
struct ConfirmImportUseCaseTests {
    @Test
    func importsTheImportableCandidatesUnderTheirPreviewedNames() async throws {
        let environment = ImportTestEnvironment()
        try await environment.storeTunnel(named: "Office", fixture: WgQuickFixtures.minimal)
        let preview = try await environment.prepareImport().execute([
            .file(name: "Office.conf", contents: Data(WgQuickFixtures.full.utf8)),
            .file(name: "Broken.conf", contents: Data("[Peer]\n".utf8)),
        ])

        let report = try await environment.confirmImport.execute(preview.candidates)

        #expect(report.importedTunnels.map(\.name.description) == ["Office 2"])
        #expect(report.failures.isEmpty)
        #expect(try await environment.records.loadRecords().map(\.name.description) == ["Office", "Office 2"])
    }
}
