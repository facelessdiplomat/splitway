public enum DiagnosticReportKind: String, Sendable, Hashable, Codable, CaseIterable {
    case crash
    case hang
    case cpuException
    case diskWriteException
    case appLaunch
}
