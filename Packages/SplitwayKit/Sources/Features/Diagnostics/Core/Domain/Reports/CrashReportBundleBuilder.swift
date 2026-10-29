import Foundation

public struct CrashReportBundleBuilder: Sendable {
    public static let defaultMaximumByteCount = 5_000_000
    private static let infoFileName = "info.txt"
    private static let logFileName = "log.txt"

    private let maximumByteCount: Int

    public init(maximumByteCount: Int = defaultMaximumByteCount) {
        self.maximumByteCount = maximumByteCount
    }

    public func bundle(info: CrashReportInfo, logEntries: [LogEntry], reports: [DiagnosticReport]) -> CrashReportBundle
    {
        let infoFile = CrashReportFile(name: Self.infoFileName, contents: Data(info.text.utf8))
        var remainingBytes = maximumByteCount - infoFile.contents.count
        let reportFiles = Self.newestReportFiles(of: reports, remainingBytes: &remainingBytes)
        let logLines = Self.newestLogLines(of: logEntries, remainingBytes: &remainingBytes)
        let logFiles =
            logLines.isEmpty ? [] : [CrashReportFile(name: Self.logFileName, contents: Data(logLines.joined().utf8))]
        return CrashReportBundle(
            files: [infoFile] + reportFiles + logFiles,
            includedLogEntryCount: logLines.count,
            includedReportCount: reportFiles.count,
            isTruncated: reportFiles.count < reports.count || logLines.count < logEntries.count
        )
    }

    private static func newestReportFiles(
        of reports: [DiagnosticReport],
        remainingBytes: inout Int
    ) -> [CrashReportFile] {
        var names = CrashReportFileNames()
        var files: [CrashReportFile] = []
        for report in reports.sorted(by: { first, second in first.date > second.date }) {
            let contents = Data(report.payload.utf8)
            guard contents.count <= remainingBytes else { continue }
            remainingBytes -= contents.count
            files.append(CrashReportFile(name: names.uniqueName(for: report), contents: contents))
        }
        return files
    }

    private static func newestLogLines(of entries: [LogEntry], remainingBytes: inout Int) -> [String] {
        var lines: [String] = []
        for entry in entries.reversed() {
            let line = LogTextFormatter.line(for: entry) + "\n"
            guard line.utf8.count <= remainingBytes else { break }
            remainingBytes -= line.utf8.count
            lines.append(line)
        }
        return lines.reversed()
    }
}
