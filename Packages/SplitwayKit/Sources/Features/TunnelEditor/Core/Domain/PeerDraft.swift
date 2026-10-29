public struct PeerDraft: Sendable, Equatable, Identifiable {
    public let id: PeerDraftID
    public var publicKey = ""
    public var presharedKey = ""
    public var allowedIPs = ""
    public var endpoint = ""
    public var persistentKeepalive = ""

    init(id: PeerDraftID) {
        self.id = id
    }

    public var fields: [PeerDraftField: String] {
        Dictionary(uniqueKeysWithValues: PeerDraftField.allCases.map { field in (field, self[field]) })
    }

    subscript(field: PeerDraftField) -> String {
        get {
            switch field {
            case .publicKey: publicKey
            case .presharedKey: presharedKey
            case .allowedIPs: allowedIPs
            case .endpoint: endpoint
            case .persistentKeepalive: persistentKeepalive
            }
        }
        set {
            switch field {
            case .publicKey: publicKey = newValue
            case .presharedKey: presharedKey = newValue
            case .allowedIPs: allowedIPs = newValue
            case .endpoint: endpoint = newValue
            case .persistentKeepalive: persistentKeepalive = newValue
            }
        }
    }
}
