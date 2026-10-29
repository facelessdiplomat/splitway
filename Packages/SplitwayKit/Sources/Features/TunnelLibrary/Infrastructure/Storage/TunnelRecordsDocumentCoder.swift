import Foundation
import TunnelLibrary

struct TunnelRecordsDocumentCoder: Sendable {
    private let migrator = JSONDocumentMigrator(upgradeSteps: [])
    private let encoder: JSONEncoder
    private let decoder = JSONDecoder()

    init() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        self.encoder = encoder
    }

    func encode(_ records: [TunnelRecord]) throws(TunnelStorageError) -> Data {
        do {
            return try encoder.encode(TunnelRecordsDocument(schemaVersion: migrator.currentVersion, tunnels: records))
        } catch {
            throw .unavailable
        }
    }

    func decode(_ data: Data) throws(TunnelStorageError) -> [TunnelRecord] {
        let currentData: Data
        do {
            currentData = try migrator.migrate(data)
        } catch .newerVersion {
            throw .unsupportedSchemaVersion
        } catch {
            throw .corruptedData
        }
        do {
            return try decoder.decode(TunnelRecordsDocument.self, from: currentData).tunnels
        } catch {
            throw .corruptedData
        }
    }
}
