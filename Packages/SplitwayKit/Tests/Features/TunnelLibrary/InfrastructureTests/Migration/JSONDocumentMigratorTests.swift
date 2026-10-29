import Foundation
import Testing
import TunnelLibraryInfrastructure

@Suite
struct JSONDocumentMigratorTests {
    private let migrator = JSONDocumentMigrator(upgradeSteps: [
        Self.appendingStage("2"),
        Self.appendingStage("3"),
    ])

    @Test
    func countsVersionsFromOneUpToTheLastUpgradeStep() {
        #expect(JSONDocumentMigrator(upgradeSteps: []).currentVersion == 1)
        #expect(migrator.currentVersion == 3)
    }

    @Test
    func upgradesAnOldDocumentThroughEveryRemainingStepInOrder() throws {
        let migrated = try Self.object(from: migrator.migrate(Data(#"{"schemaVersion":1,"stage":"1"}"#.utf8)))

        #expect(migrated["schemaVersion"] as? Int == 3)
        #expect(migrated["stage"] as? String == "1-2-3")
    }

    @Test
    func startsUpgradingFromTheDocumentsOwnVersion() throws {
        let migrated = try Self.object(from: migrator.migrate(Data(#"{"schemaVersion":2,"stage":"2"}"#.utf8)))

        #expect(migrated["stage"] as? String == "2-3")
    }

    @Test
    func returnsACurrentDocumentUntouched() throws {
        let currentDocument = Data(#"{ "stage" : "3", "schemaVersion" : 3 }"#.utf8)

        #expect(try migrator.migrate(currentDocument) == currentDocument)
    }

    @Test
    func rejectsADocumentFromANewerVersion() {
        #expect(throws: JSONDocumentMigrationError.newerVersion(4)) {
            try migrator.migrate(Data(#"{"schemaVersion":4}"#.utf8))
        }
    }

    @Test(arguments: [
        "not json",
        "[]",
        "{}",
        #"{"schemaVersion":"1"}"#,
        #"{"schemaVersion":0}"#,
        #"{"schemaVersion":1.5}"#,
    ])
    func rejectsADocumentWithoutAUsableVersion(_ text: String) {
        #expect(throws: JSONDocumentMigrationError.malformedDocument) {
            try migrator.migrate(Data(text.utf8))
        }
    }

    @Test
    func rejectsAnUpgradeThatLeavesValuesJSONCannotHold() {
        let migrator = JSONDocumentMigrator(upgradeSteps: [{ document in document["migratedAt"] = Date() }])

        #expect(throws: JSONDocumentMigrationError.malformedDocument) {
            try migrator.migrate(Data(#"{"schemaVersion":1}"#.utf8))
        }
    }

    private static func appendingStage(_ stage: String) -> JSONDocumentMigrator.UpgradeStep {
        { document in
            let previousStages = document["stage"] as? String ?? ""
            document["stage"] = "\(previousStages)-\(stage)"
        }
    }

    private static func object(from data: Data) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
