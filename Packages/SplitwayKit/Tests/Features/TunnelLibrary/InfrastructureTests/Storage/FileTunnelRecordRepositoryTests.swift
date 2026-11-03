import AppRouting
import Foundation
import SharedKernelTestSupport
import Testing
import TunnelLibrary
import TunnelLibraryInfrastructure

@Suite
final class FileTunnelRecordRepositoryTests {
    private static let firstSchemaVersionDocument = """
        {
          "schemaVersion" : 1,
          "tunnels" : [
            {
              "id" : "0B7C5A2E-4D7F-4C11-9E55-3C2A1F6B8D01",
              "name" : "Office",
              "routingPolicy" : {
                "mode" : "allTraffic",
                "schemaVersion" : 1,
                "whenTunnelUnavailable" : "block"
              }
            },
            {
              "id" : "7E1D9C44-2B3A-4F6E-8A90-5D4C3B2A1F02",
              "name" : "Prague",
              "routingPolicy" : {
                "applications" : [
                  {
                    "displayName" : "curl",
                    "kind" : "commandLineTool",
                    "path" : "/usr/bin/curl",
                    "signingIdentifiers" : []
                  }
                ],
                "mode" : "selectedApplications",
                "schemaVersion" : 1,
                "whenTunnelUnavailable" : "bypass"
              }
            }
          ]
        }
        """

    private let directory = FileManager.default.temporaryDirectory.appending(path: "splitway-\(UUID().uuidString)")
    private let corruptionMoment: Date

    init() throws {
        corruptionMoment = try Date("2026-10-29T10:15:00Z", strategy: .iso8601)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func returnsNoRecordsBeforeAnythingIsSaved() async throws {
        #expect(try await makeRepository().loadRecords().isEmpty)
    }

    @Test
    func keepsRecordsAcrossRepositoryInstances() async throws {
        let records = try Self.firstSchemaVersionRecords()

        try await makeRepository().saveRecords(records)

        #expect(try await makeRepository().loadRecords() == records)
    }

    @Test
    func createsMissingDirectoriesOnFirstSave() async throws {
        let nestedDirectory = directory.appending(path: "Library/Application Support/Splitway")

        try await FileTunnelRecordRepository(directory: nestedDirectory).saveRecords([])

        #expect(Self.fileExists(nestedDirectory.appending(path: "tunnels.json")))
    }

    @Test
    func readsTheFirstSchemaVersionFormat() async throws {
        try writeDocument(Self.firstSchemaVersionDocument)

        #expect(try await makeRepository().loadRecords() == Self.firstSchemaVersionRecords())
    }

    @Test
    func writesTheFirstSchemaVersionFormat() async throws {
        try await makeRepository().saveRecords(Self.firstSchemaVersionRecords())

        #expect(try storedDocument() == Self.jsonObject(Self.firstSchemaVersionDocument))
    }

    @Test
    func movesACorruptedDocumentAsideAndStartsEmpty() async throws {
        try writeDocument("{not json")
        let repository = makeRepository()

        await #expect(throws: TunnelStorageError.corruptedData) {
            try await repository.loadRecords()
        }

        let backupURL = directory.appending(path: "tunnels.corrupted-20261029T101500Z.json")
        #expect(try String(contentsOf: backupURL, encoding: .utf8) == "{not json")
        #expect(try await repository.loadRecords().isEmpty)
    }

    @Test
    func treatsRecordsThatFailValidationAsCorruption() async throws {
        try writeDocument(Self.firstSchemaVersionDocument.replacingOccurrences(of: "\"Office\"", with: "\"\""))
        let repository = makeRepository()

        await #expect(throws: TunnelStorageError.corruptedData) {
            try await repository.loadRecords()
        }
    }

    @Test
    func leavesADocumentFromANewerVersionInPlace() async throws {
        let newerDocument = #"{"schemaVersion":999,"tunnels":[]}"#
        try writeDocument(newerDocument)
        let repository = makeRepository()

        await #expect(throws: TunnelStorageError.unsupportedSchemaVersion) {
            try await repository.loadRecords()
        }

        #expect(try storedFileNames() == ["tunnels.json"])
        #expect(try String(contentsOf: documentURL, encoding: .utf8) == newerDocument)
    }

    @Test
    func reportsAnUnreadableDocumentAsUnavailableWithoutMovingIt() async throws {
        try FileManager.default.createDirectory(at: documentURL, withIntermediateDirectories: true)
        let repository = makeRepository()

        await #expect(throws: TunnelStorageError.unavailable) {
            try await repository.loadRecords()
        }

        #expect(try storedFileNames() == ["tunnels.json"])
    }

    @Test
    func reportsAnUnwritableDirectoryAsUnavailable() async throws {
        try writeDocument("")
        let repository = FileTunnelRecordRepository(directory: documentURL)

        await #expect(throws: TunnelStorageError.unavailable) {
            try await repository.saveRecords([])
        }
    }

    private var documentURL: URL {
        directory.appending(path: "tunnels.json")
    }

    private func makeRepository() -> FileTunnelRecordRepository {
        FileTunnelRecordRepository(directory: directory, clock: FixedWallClock(corruptionMoment))
    }

    private func writeDocument(_ text: String) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(text.utf8).write(to: documentURL)
    }

    private func storedFileNames() throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false))
    }

    private func storedDocument() throws -> NSDictionary? {
        try Self.jsonObject(String(contentsOf: documentURL, encoding: .utf8))
    }

    private static func fileExists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
    }

    private static func jsonObject(_ text: String) throws -> NSDictionary? {
        try JSONSerialization.jsonObject(with: Data(text.utf8)) as? NSDictionary
    }

    private static func firstSchemaVersionRecords() throws -> [TunnelRecord] {
        [
            TunnelRecord(
                id: TunnelIdentifier(try #require(UUID(uuidString: "0B7C5A2E-4D7F-4C11-9E55-3C2A1F6B8D01"))),
                name: try TunnelName("Office"),
                routingPolicy: .default
            ),
            TunnelRecord(
                id: TunnelIdentifier(try #require(UUID(uuidString: "7E1D9C44-2B3A-4F6E-8A90-5D4C3B2A1F02"))),
                name: try TunnelName("Prague"),
                routingPolicy: RoutingPolicy(
                    mode: .selectedApplications(
                        ApplicationSelection([
                            try ApplicationIdentity(kind: .commandLineTool, displayName: "curl", path: "/usr/bin/curl")
                        ])
                    ),
                    whenTunnelUnavailable: .bypass
                )
            ),
        ]
    }
}
