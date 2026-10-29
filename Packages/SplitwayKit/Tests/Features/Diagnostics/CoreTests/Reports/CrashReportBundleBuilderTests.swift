import Diagnostics
import Foundation
import Testing

@Suite
struct CrashReportBundleBuilderTests {
    private static let moment = Date(timeIntervalSince1970: 1_793_268_900)
    private static let info = CrashReportInfo(application: "Splitway 0.1.0 (1)", system: "iOS 26.0", createdAt: moment)

    @Test
    func bundlesTheAppInfoTheLogAndEveryReport() {
        let entries = [LogEntry(date: Self.moment, level: .info, source: .application, message: "Started")]
        let reports = [
            DiagnosticReport(kind: .crash, date: Self.moment, payload: "{\"crash\":1}"),
            DiagnosticReport(kind: .crash, date: Self.moment, payload: "{\"crash\":2}"),
        ]

        let bundle = CrashReportBundleBuilder().bundle(info: Self.info, logEntries: entries, reports: reports)

        #expect(
            bundle.files.map(\.name) == [
                "info.txt", "crash-2026-10-29T10-15-00Z.json", "crash-2026-10-29T10-15-00Z-2.json", "log.txt",
            ])
        #expect(bundle.includedLogEntryCount == 1)
        #expect(bundle.includedReportCount == 2)
        #expect(!bundle.isTruncated)
        #expect(!bundle.isEmpty)
    }

    @Test
    func masksKeysInTheLogAndTheReports() throws {
        let key = Data(repeating: 7, count: 32).base64EncodedString()
        let entries = [LogEntry(date: Self.moment, level: .error, source: .engine, message: "peer \(key) failed")]
        let reports = [DiagnosticReport(kind: .hang, date: Self.moment, payload: "{\"note\":\"PrivateKey = \(key)\"}")]

        let bundle = CrashReportBundleBuilder().bundle(info: Self.info, logEntries: entries, reports: reports)

        let text = try bundle.files.map(Self.text(of:)).joined()
        #expect(!text.contains(key))
        #expect(text.contains(LogRedactor.mask))
    }

    @Test
    func holdsOnlyTheAppInfoWhenNothingWasRecorded() throws {
        let bundle = CrashReportBundleBuilder().bundle(info: Self.info, logEntries: [], reports: [])

        let info = try #require(bundle.files.only)
        #expect(info.name == "info.txt")
        #expect(try Self.text(of: info).hasPrefix("Splitway 0.1.0 (1)\niOS 26.0\n"))
        #expect(bundle.isEmpty)
    }

    @Test
    func keepsTheNewestEntriesWithinTheSizeLimit() throws {
        let entries = (0..<100).map { index in
            LogEntry(
                date: Self.moment.addingTimeInterval(Double(index)), level: .info, source: .application,
                message: "Entry \(index)")
        }

        let bundle = CrashReportBundleBuilder(maximumByteCount: 1_000)
            .bundle(info: Self.info, logEntries: entries, reports: [])

        let log = try Self.text(of: try #require(bundle.files.last))
        #expect(bundle.byteCount <= 1_000)
        #expect(bundle.isTruncated)
        #expect(log.hasSuffix("Entry 99\n"))
        #expect(!log.contains("Entry 0\n"))
    }

    @Test
    func keepsReportsBeforeOldLogEntries() {
        let entries = (0..<50).map { index in
            LogEntry(date: Self.moment, level: .info, source: .application, message: "Entry \(index)")
        }
        let report = DiagnosticReport(kind: .crash, date: Self.moment, payload: String(repeating: "x", count: 600))

        let bundle = CrashReportBundleBuilder(maximumByteCount: 1_000)
            .bundle(info: Self.info, logEntries: entries, reports: [report])

        #expect(bundle.includedReportCount == 1)
        #expect(bundle.includedLogEntryCount < 50)
        #expect(bundle.byteCount <= 1_000)
    }
}

extension CrashReportBundleBuilderTests {
    fileprivate static func text(of file: CrashReportFile) throws -> String {
        try #require(String(bytes: file.contents, encoding: .utf8))
    }
}

extension Array {
    fileprivate var only: Element? {
        count == 1 ? first : nil
    }
}
