public enum ProxiedFlowError: Error, Equatable, Sendable {
    case refused
    case timedOut
    case peerReset
    case aborted
}
