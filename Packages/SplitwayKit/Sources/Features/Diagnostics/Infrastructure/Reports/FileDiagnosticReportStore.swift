import Diagnostics
import Foundation

public struct FileDiagnosticReportStore: DiagnosticReportHistory {
    public static let maximumReportCount = 20
    private static let queue = DispatchQueue(label: "Splitway.DiagnosticReports", qos: .utility)
    private static let fileExtension = "json"

    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func save(_ reports: [DiagnosticReport]) throws(DiagnosticReportStoreError) {
        guard !reports.isEmpty else { return }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            for report in reports {
                let stored = StoredDiagnosticReport(kind: report.kind, date: report.date, payload: report.payload)
                let file = directory.appending(path: "\(UUID().uuidString).\(Self.fileExtension)")
                try encoder.encode(stored).write(to: file, options: .atomic)
            }
            try removeReportsBeyondLimit()
        } catch {
            throw .unavailable
        }
    }

    public func reports() async throws(DiagnosticReportStoreError) -> [DiagnosticReport] {
        try await queuedReports().get()
    }

    private func queuedReports() async -> Result<[DiagnosticReport], DiagnosticReportStoreError> {
        await withCheckedContinuation { continuation in
            Self.queue.async {
                continuation.resume(returning: Result(catching: readReports))
            }
        }
    }

    private func readReports() throws(DiagnosticReportStoreError) -> [DiagnosticReport] {
        try storedReports().map(\.report)
    }

    private func storedReports() throws(DiagnosticReportStoreError) -> [(file: URL, report: DiagnosticReport)] {
        guard FileManager.default.fileExists(atPath: directory.path()) else { return [] }
        let files: [URL]
        do {
            files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        } catch {
            throw .unavailable
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return files.filter { file in file.pathExtension == Self.fileExtension }
            .compactMap { file in
                guard let data = try? Data(contentsOf: file),
                    let stored = try? decoder.decode(StoredDiagnosticReport.self, from: data)
                else { return nil }
                return (file, DiagnosticReport(kind: stored.kind, date: stored.date, payload: stored.payload))
            }
            .sorted { first, second in first.report.date < second.report.date }
    }

    private func removeReportsBeyondLimit() throws {
        let stored = try storedReports()
        for (file, _) in stored.dropLast(Self.maximumReportCount) {
            try FileManager.default.removeItem(at: file)
        }
    }
}
