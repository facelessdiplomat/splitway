public enum TunnelExportProblem: Sendable, Equatable {
    case failed
    case skippedTunnels([String])
}
