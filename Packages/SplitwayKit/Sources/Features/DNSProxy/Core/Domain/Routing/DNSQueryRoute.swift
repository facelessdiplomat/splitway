public enum DNSQueryRoute: Sendable, Hashable {
    case throughTunnel
    case toOriginalResolver
    case refuse
}
