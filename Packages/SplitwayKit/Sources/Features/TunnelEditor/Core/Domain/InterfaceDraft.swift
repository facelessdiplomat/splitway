import TunnelConfiguration

public struct InterfaceDraft: Sendable, Equatable {
    public var privateKey = ""
    public var addresses = ""
    public var listenPort = ""
    public var mtu = ""
    public var dns = ""

    public var publicKey: String? {
        let privateKeyText = privateKey.trimmingCharacters(in: .whitespaces)
        return (try? WgQuickValueConversions.privateKey(privateKeyText))?.publicKey.base64EncodedText
    }

    subscript(field: InterfaceDraftField) -> String {
        get {
            switch field {
            case .privateKey: privateKey
            case .addresses: addresses
            case .listenPort: listenPort
            case .mtu: mtu
            case .dns: dns
            }
        }
        set {
            switch field {
            case .privateKey: privateKey = newValue
            case .addresses: addresses = newValue
            case .listenPort: listenPort = newValue
            case .mtu: mtu = newValue
            case .dns: dns = newValue
            }
        }
    }
}
