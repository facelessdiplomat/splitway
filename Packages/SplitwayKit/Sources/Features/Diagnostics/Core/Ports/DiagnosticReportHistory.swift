public protocol DiagnosticReportHistory: Sendable {
    func reports() async throws(DiagnosticReportStoreError) -> [DiagnosticReport]
}
