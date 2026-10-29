import Diagnostics
import DiagnosticsInfrastructure
import Foundation
import Testing

@Suite
final class DiagnosticsAssemblyTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "DiagnosticsAssemblyTests-\(UUID().uuidString)")

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test
    func showsTheEntriesOfTheAppAndTheExtensionInOneList() async throws {
        let appEntry = LogEntry(
            date: Date(timeIntervalSince1970: 1_793_268_900), level: .info, source: .application, message: "Started")
        let extensionEntry = LogEntry(
            date: Date(timeIntervalSince1970: 1_793_268_901), level: .info, source: .tunnelExtension,
            message: "Tunnel up")
        try RotatingFileLogStore(directory: directory).append(appEntry)
        try RotatingFileLogStore(directory: directory).append(extensionEntry)
        let assembly = DiagnosticsAssembly(logDirectory: directory, subsystem: "Splitway.Tests")

        let entries = try await assembly.loadLogEntries.execute()

        #expect(entries == [extensionEntry, appEntry])
    }
}
