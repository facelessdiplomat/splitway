#if canImport(MetricKit)
    import Diagnostics
    import Foundation
    import MetricKit

    enum MetricKitReportConversion {
        static func reports(from payloads: [MXDiagnosticPayload]) -> [Diagnostics.DiagnosticReport] {
            payloads.flatMap { payload in
                diagnostics(of: payload).compactMap { kind, diagnostic in
                    String(bytes: diagnostic.jsonRepresentation(), encoding: .utf8).map { text in
                        Diagnostics.DiagnosticReport(kind: kind, date: payload.timeStampEnd, payload: text)
                    }
                }
            }
        }

        private static func diagnostics(of payload: MXDiagnosticPayload) -> [(DiagnosticReportKind, MXDiagnostic)] {
            var diagnostics: [(DiagnosticReportKind, MXDiagnostic)] = []
            diagnostics += (payload.crashDiagnostics ?? []).map { diagnostic in (.crash, diagnostic) }
            diagnostics += (payload.hangDiagnostics ?? []).map { diagnostic in (.hang, diagnostic) }
            diagnostics += (payload.cpuExceptionDiagnostics ?? []).map { diagnostic in (.cpuException, diagnostic) }
            diagnostics += (payload.diskWriteExceptionDiagnostics ?? []).map { diagnostic in
                (.diskWriteException, diagnostic)
            }
            return diagnostics
        }
    }
#endif
