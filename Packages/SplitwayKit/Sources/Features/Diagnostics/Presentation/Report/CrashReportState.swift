import Diagnostics

public enum CrashReportState: Sendable, Equatable {
    case preparing
    case ready(PreparedCrashReport)
    case unavailable
}
