public enum WgQuickSection: Sendable, Hashable {
    case interface
    case peer

    init?(name: String) {
        switch name.lowercased() {
        case "interface": self = .interface
        case "peer": self = .peer
        default: return nil
        }
    }
}
