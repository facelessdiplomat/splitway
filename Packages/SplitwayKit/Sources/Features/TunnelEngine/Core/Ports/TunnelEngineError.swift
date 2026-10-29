public enum TunnelEngineError: Error, Equatable, Sendable {
    case tunnelInterfaceUnavailable
    case configurationRejected
    case socketsUnavailable
    case deviceNotRunning
    case unreadableStatistics
    case internalFailure
}
