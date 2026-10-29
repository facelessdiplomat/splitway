import TunnelConfiguration

public enum PeerDraftField: Sendable, Hashable, CaseIterable {
    case publicKey
    case presharedKey
    case allowedIPs
    case endpoint
    case persistentKeepalive

    init?(key: WgQuickKey) {
        guard let field = Self.allCases.first(where: { field in field.key == key }) else { return nil }
        self = field
    }

    var key: WgQuickKey {
        switch self {
        case .publicKey: .publicKey
        case .presharedKey: .presharedKey
        case .allowedIPs: .allowedIPs
        case .endpoint: .endpoint
        case .persistentKeepalive: .persistentKeepalive
        }
    }

    var isList: Bool {
        self == .allowedIPs
    }
}
