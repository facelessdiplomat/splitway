import Foundation

public struct DiagnosticReport: Sendable, Hashable {
    public let kind: DiagnosticReportKind
    public let date: Date
    public let payload: String

    public init(kind: DiagnosticReportKind, date: Date, payload: String) {
        self.kind = kind
        self.date = date
        self.payload = LogRedactor.redact(payload)
    }
}
