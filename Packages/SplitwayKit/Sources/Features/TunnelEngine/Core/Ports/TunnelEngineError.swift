public enum TunnelEngineError: Error, Equatable, Sendable {
    case tunnelInterfaceUnavailable
    case configurationRejected
    case deviceNotRunning
    case unreadableStatistics
    case internalFailure
}
