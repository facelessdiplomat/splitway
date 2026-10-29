import TunnelConfiguration

public enum InterfaceDraftField: Sendable, Hashable, CaseIterable {
    case privateKey
    case addresses
    case listenPort
    case mtu
    case dns

    init?(key: WgQuickKey) {
        guard let field = Self.allCases.first(where: { field in field.key == key }) else { return nil }
        self = field
    }

    var key: WgQuickKey {
        switch self {
        case .privateKey: .privateKey
        case .addresses: .address
        case .listenPort: .listenPort
        case .mtu: .mtu
        case .dns: .dns
        }
    }

    var isList: Bool {
        self == .addresses || self == .dns
    }
}
