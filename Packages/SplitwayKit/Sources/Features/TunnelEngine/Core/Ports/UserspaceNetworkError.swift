public enum UserspaceNetworkError: Error, Equatable, Sendable {
    case connectionFailed
    case timedOut
    case lookupFailed
    case networkStopped
    case connectionClosed
    case internalFailure
}
