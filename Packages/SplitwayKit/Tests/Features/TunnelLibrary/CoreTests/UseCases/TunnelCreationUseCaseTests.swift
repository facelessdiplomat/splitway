import AppRouting
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelLibrary

@Suite
struct TunnelCreationUseCaseTests {
    @Test
    func storesTheConfigurationAsASecretAndTheRecordSeparately() async throws {
        let environment = LibraryTestEnvironment()

        let tunnel = try await environment.storedTunnel(named: "Office")

        #expect(
            await environment.records.records == [
                TunnelRecord(id: tunnel.id, name: tunnel.name, routingPolicy: .default)
            ])
        #expect(
            await environment.secrets.texts[tunnel.id] == WgQuickConfigurationSerializer.serialize(tunnel.configuration)
        )
    }

    @Test
    func resolvesNameConflictsOnCreation() async throws {
        let environment = LibraryTestEnvironment()

        try await environment.storedTunnel(named: "Office")
        let second = try await environment.storedTunnel(named: "office")

        #expect(second.name.description == "office 2")
    }

    @Test
    func removesTheSecretWhenTheRecordCannotBeSaved() async throws {
        let environment = LibraryTestEnvironment()
        await environment.records.failSaves(afterSuccessfulSaves: 0)

        await #expect(throws: TunnelLibraryError.storage(.unavailable)) {
            try await environment.storedTunnel(named: "Office")
        }
        #expect(await environment.secrets.texts.isEmpty)
    }

    @Test
    func importsABatchWithUniqueNames() async throws {
        let environment = LibraryTestEnvironment()
        let configuration = try environment.configuration(of: WgQuickFixtures.minimal)
        let candidate = ImportCandidate(proposedName: try TunnelName("cz-prg"), configuration: configuration)

        let report = try await environment.importTunnels.execute([candidate, candidate, candidate])

        #expect(report.importedTunnels.map(\.name.description) == ["cz-prg", "cz-prg 2", "cz-prg 3"])
        #expect(report.failures.isEmpty)
    }

    @Test
    func keepsImportingAfterACandidateCannotBeStored() async throws {
        let environment = LibraryTestEnvironment()
        let configuration = try environment.configuration(of: WgQuickFixtures.minimal)
        let candidates = try ["First", "Second", "Third"].map { name in
            ImportCandidate(proposedName: try TunnelName(name), configuration: configuration)
        }
        await environment.secrets.failSave(number: 2)

        let report = try await environment.importTunnels.execute(candidates)

        #expect(report.importedTunnels.map(\.name.description) == ["First", "Third"])
        #expect(report.failures.map(\.candidate.proposedName.description) == ["Second"])
        #expect(report.failures.map(\.error) == [.storage(.unavailable)])
        #expect(await environment.records.records.map(\.name.description) == ["First", "Third"])
    }

    @Test
    func loadsTunnelsInStoredOrderAndReportsUnreadableRecords() async throws {
        let environment = LibraryTestEnvironment()
        let office = try await environment.storedTunnel(named: "Office")
        let home = try await environment.storedTunnel(named: "Home", fixture: WgQuickFixtures.full)
        let broken = try await environment.storedTunnel(named: "Broken")
        try await environment.secrets.deleteConfigurationText(for: broken.id)

        let snapshot = try await environment.loadTunnels.execute()

        #expect(snapshot.tunnels == [office, home])
        #expect(snapshot.unreadableRecords.map(\.id) == [broken.id])
    }

    @Test
    func keepsAnUnreadableRecordInItsStoredPlace() async throws {
        let environment = LibraryTestEnvironment()
        let office = try await environment.storedTunnel(named: "Office")
        let broken = try await environment.storedTunnel(named: "Broken")
        let home = try await environment.storedTunnel(named: "Home")
        try await environment.secrets.deleteConfigurationText(for: broken.id)

        let snapshot = try await environment.loadTunnels.execute()

        #expect(snapshot.entries.map(\.id) == [office.id, broken.id, home.id])
        #expect(snapshot.entries.map(\.name) == [office.name, broken.name, home.name])
    }
}
