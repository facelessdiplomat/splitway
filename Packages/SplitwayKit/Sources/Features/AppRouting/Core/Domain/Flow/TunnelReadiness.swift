public enum TunnelReadiness: Sendable, Hashable {
    case ready(carriesIPv6: Bool)
    case unavailable
}
