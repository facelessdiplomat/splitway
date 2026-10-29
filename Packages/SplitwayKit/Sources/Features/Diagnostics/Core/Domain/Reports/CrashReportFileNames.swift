import Foundation

struct CrashReportFileNames {
    private var usedNames: Set<String> = []

    mutating func uniqueName(for report: DiagnosticReport) -> String {
        let base = "\(report.kind.rawValue)-\(Self.timestamp(of: report.date))"
        var name = "\(base).json"
        var copyNumber = 2
        while usedNames.contains(name) {
            name = "\(base)-\(copyNumber).json"
            copyNumber += 1
        }
        usedNames.insert(name)
        return name
    }

    private static func timestamp(of date: Date) -> String {
        date.formatted(.iso8601).replacingOccurrences(of: ":", with: "-")
    }
}
