import Foundation
import SharedKernel
import TunnelLibrary

public actor FileTunnelRecordRepository: TunnelRecordRepository {
    private static let documentFileName = "tunnels.json"

    private let directory: URL
    private let documentURL: URL
    private let coder = TunnelRecordsDocumentCoder()
    private let quarantine: CorruptedDocumentQuarantine

    public init(directory: URL, clock: any WallClock = SystemWallClock()) {
        self.directory = directory
        documentURL = directory.appending(path: Self.documentFileName)
        quarantine = CorruptedDocumentQuarantine(clock: clock)
    }

    public func loadRecords() async throws(TunnelStorageError) -> [TunnelRecord] {
        guard let storedData = try readStoredDocument() else { return [] }
        do {
            return try coder.decode(storedData)
        } catch .corruptedData {
            quarantine.moveAside(documentURL)
            throw .corruptedData
        }
    }

    public func saveRecords(_ records: [TunnelRecord]) async throws(TunnelStorageError) {
        let data = try coder.encode(records)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: documentURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            throw .unavailable
        }
    }

    private func readStoredDocument() throws(TunnelStorageError) -> Data? {
        do {
            return try Data(contentsOf: documentURL)
        } catch CocoaError.fileReadNoSuchFile {
            return nil
        } catch {
            throw .unavailable
        }
    }
}
