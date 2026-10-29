public enum RuntimeStatisticsError: Error, Equatable, Sendable {
    case tunnelNotRunning
    case extensionUnavailable
    case incompatibleExtension
    case unexpectedResponse
}
