import Diagnostics
import Foundation

struct StoredDiagnosticReport: Codable {
    let kind: DiagnosticReportKind
    let date: Date
    let payload: String
}
