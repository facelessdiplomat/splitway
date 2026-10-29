public enum TunnelLibraryEntry: Sendable, Hashable {
    case readable(Tunnel)
    case unreadable(TunnelRecord)

    public var id: TunnelIdentifier {
        switch self {
        case .readable(let tunnel): tunnel.id
        case .unreadable(let record): record.id
        }
    }

    public var name: TunnelName {
        switch self {
        case .readable(let tunnel): tunnel.name
        case .unreadable(let record): record.name
        }
    }
}
