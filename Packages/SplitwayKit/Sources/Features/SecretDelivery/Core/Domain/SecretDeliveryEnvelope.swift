import TunnelLibrary

struct SecretDeliveryEnvelope: Codable {
    enum Kind: String, Codable {
        case store
        case remove
        case removeAll
        case done
        case failed
    }

    struct Version: Decodable {
        let schemaVersion: Int
    }

    var schemaVersion = SecretDeliveryCodec.schemaVersion
    let kind: Kind
    var tunnel: TunnelIdentifier?
    var configurationText: String?
    var failure: SecretDeliveryFailure?
}
