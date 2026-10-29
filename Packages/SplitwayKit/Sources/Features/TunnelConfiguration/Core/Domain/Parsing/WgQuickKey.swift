public enum WgQuickKey: Sendable, Hashable, CaseIterable {
    case privateKey
    case address
    case dns
    case mtu
    case listenPort
    case publicKey
    case presharedKey
    case allowedIPs
    case endpoint
    case persistentKeepalive

    private static let keysByLowercasedName = Dictionary(
        uniqueKeysWithValues: allCases.map { key in (key.name.lowercased(), key) }
    )

    init?(name: String) {
        guard let key = Self.keysByLowercasedName[name.lowercased()] else { return nil }
        self = key
    }

    public var name: String {
        switch self {
        case .privateKey: "PrivateKey"
        case .address: "Address"
        case .dns: "DNS"
        case .mtu: "MTU"
        case .listenPort: "ListenPort"
        case .publicKey: "PublicKey"
        case .presharedKey: "PresharedKey"
        case .allowedIPs: "AllowedIPs"
        case .endpoint: "Endpoint"
        case .persistentKeepalive: "PersistentKeepalive"
        }
    }

    var section: WgQuickSection {
        switch self {
        case .privateKey, .address, .dns, .mtu, .listenPort: .interface
        case .publicKey, .presharedKey, .allowedIPs, .endpoint, .persistentKeepalive: .peer
        }
    }

    var acceptsMultipleLines: Bool {
        switch self {
        case .address, .dns, .allowedIPs: true
        default: false
        }
    }
}
