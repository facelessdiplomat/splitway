import Foundation
import Testing
import TunnelConfigurationTestSupport
import TunnelLibrary
import TunnelLibraryPresentation

@MainActor
@Suite
struct TunnelExportModelTests {
    @Test
    func warnsAboutPrivateKeysBeforeExportingATunnel() async throws {
        let environment = TunnelExportTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")

        environment.model.requestExport(of: office.id, named: "Office")

        #expect(environment.model.pendingExport == .tunnel(office.id, name: "Office"))
        #expect(environment.model.document == nil)
    }

    @Test
    func warnsEveryTime() async throws {
        let environment = TunnelExportTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        environment.model.requestExport(of: office.id, named: "Office")
        environment.model.cancelExport()

        environment.model.requestExportOfAllTunnels()

        #expect(environment.model.pendingExport == .allTunnels)
    }

    @Test
    func namesTheExportedFileAfterTheTunnel() async throws {
        let environment = TunnelExportTestEnvironment()
        let office = try await environment.storeTunnel(named: "Office")
        environment.model.requestExport(of: office.id, named: "Office")

        await environment.model.confirmExport()

        let document = try #require(environment.model.document)
        #expect(document.fileName == "Office.conf")
        #expect(document.kind == .configuration)
        #expect(String(bytes: document.contents, encoding: .utf8)?.contains("[Interface]") == true)
        #expect(environment.model.pendingExport == nil)
    }

    @Test
    func namesTheArchiveOfAllTunnels() async throws {
        let environment = TunnelExportTestEnvironment()
        _ = try await environment.storeTunnel(named: "Office")
        environment.model.requestExportOfAllTunnels()

        await environment.model.confirmExport()

        let document = try #require(environment.model.document)
        #expect(document.fileName == "Splitway Tunnels.zip")
        #expect(document.kind == .archive)
        #expect(String(bytes: document.contents, encoding: .utf8) == "Office.conf")
    }

    @Test
    func reportsTunnelsLeftOutOfTheArchiveOnceItIsSaved() async throws {
        let environment = TunnelExportTestEnvironment()
        _ = try await environment.storeTunnel(named: "Office")
        let broken = try await environment.storeTunnel(named: "Broken")
        try await environment.secrets.deleteConfigurationText(for: broken.id)
        environment.model.requestExportOfAllTunnels()
        await environment.model.confirmExport()
        #expect(environment.model.problem == nil)

        environment.model.finishExport(succeeded: true)

        #expect(environment.model.document == nil)
        #expect(environment.model.problem == .skippedTunnels(["Broken"]))
    }

    @Test
    func reportsAnExportThatFailed() async throws {
        let environment = TunnelExportTestEnvironment()
        environment.model.requestExport(of: TunnelIdentifier(), named: "Gone")

        await environment.model.confirmExport()

        #expect(environment.model.document == nil)
        #expect(environment.model.problem == .failed)
    }
}
