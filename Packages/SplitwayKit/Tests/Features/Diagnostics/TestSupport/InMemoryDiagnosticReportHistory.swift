import Diagnostics

public actor InMemoryDiagnosticReportHistory: DiagnosticReportHistory {
    private var storedReports: [DiagnosticReport]
    private let isAvailable: Bool

    public init(reports: [DiagnosticReport] = [], isAvailable: Bool = true) {
        storedReports = reports
        self.isAvailable = isAvailable
    }

    public func reports() throws(DiagnosticReportStoreError) -> [DiagnosticReport] {
        guard isAvailable else { throw .unavailable }
        return storedReports
    }
}
