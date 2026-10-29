import Foundation
import Testing
import TunnelConfiguration
import TunnelLibrary
import TunnelLibraryTestSupport

@Suite
struct TunnelRemovalAndExportUseCaseTests {
    @Test
    func stopsAnActiveTunnelBeforeDeletingIt() async throws {
        let environment = LibraryTestEnvironment()
        let tunnel = try await environment.storedTunnel(named: "Office")
        let probe = FakeTunnelActivityProbe(activeTunnels: [tunnel.id])

        try await environment.deleteTunnel(probe: probe).execute(id: tunnel.id)

        #expect(await probe.stoppedTunnels == [tunnel.id])
        #expect(await environment.records.records.isEmpty)
        #expect(await environment.secrets.texts.isEmpty)
    }

    @Test
    func keepsATunnelThatCannotBeStopped() async throws {
        let environment = LibraryTestEnvironment()
        let tunnel = try await environment.storedTunnel(named: "Office")
        let probe = FakeTunnelActivityProbe(activeTunnels: [tunnel.id], stopSucceeds: false)

        await #expect(throws: TunnelLibraryError.activeTunnelCouldNotBeStopped) {
            try await environment.deleteTunnel(probe: probe).execute(id: tunnel.id)
        }
        #expect(await environment.records.records.map(\.id) == [tunnel.id])
        #expect(await environment.secrets.texts[tunnel.id] != nil)
    }

    @Test
    func restoresTheSecretWhenTheRecordsCannotBeSavedAfterDeletion() async throws {
        let environment = LibraryTestEnvironment()
        let tunnel = try await environment.storedTunnel(named: "Office")
        await environment.records.failSaves(afterSuccessfulSaves: 0)

        await #expect(throws: TunnelLibraryError.storage(.unavailable)) {
            try await environment.deleteTunnel(probe: FakeTunnelActivityProbe()).execute(id: tunnel.id)
        }
        #expect(await environment.secrets.texts[tunnel.id] != nil)
    }

    @Test
    func exportsOneTunnelAsCanonicalTextWithASafeFileName() async throws {
        let environment = LibraryTestEnvironment()
        let tunnel = try await environment.storedTunnel(named: "Home/Office: main")

        let file = try await environment.exportTunnels().exportConfiguration(of: tunnel.id)

        #expect(file.fileName == "Home-Office- main.conf")
        #expect(file.contents == WgQuickConfigurationSerializer.serialize(tunnel.configuration))
    }

    @Test
    func exportsEveryTunnelIntoOneArchiveWithUniqueFileNames() async throws {
        let environment = LibraryTestEnvironment()
        try await environment.storedTunnel(named: "a/b")
        try await environment.storedTunnel(named: "a-b")

        let archive = try await environment.exportTunnels().exportAll()

        #expect(String(bytes: archive.contents, encoding: .utf8) == "a-b.conf\na-b 2.conf")
        #expect(archive.skippedTunnels.isEmpty)
    }

    @Test
    func leavesOutTunnelsWhoseConfigurationIsUnreadable() async throws {
        let environment = LibraryTestEnvironment()
        try await environment.storedTunnel(named: "Office")
        let broken = try await environment.storedTunnel(named: "Broken")
        try await environment.secrets.deleteConfigurationText(for: broken.id)

        let archive = try await environment.exportTunnels().exportAll()

        #expect(String(bytes: archive.contents, encoding: .utf8) == "Office.conf")
        #expect(archive.skippedTunnels.map(\.description) == ["Broken"])
    }

    @Test
    func reportsArchiveFailures() async throws {
        let environment = LibraryTestEnvironment()
        try await environment.storedTunnel(named: "Office")

        await #expect(throws: TunnelLibraryError.archiveFailed) {
            try await environment.exportTunnels(archiveWriter: ListingArchiveWriter(fails: true)).exportAll()
        }
    }
}
