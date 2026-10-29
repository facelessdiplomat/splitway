import CryptoKit

public struct PrivateKey: Sendable, Hashable {
    let key: WireGuardKey
    public let publicKey: PublicKey

    public init(base64Encoded text: String) throws(WireGuardKeyParsingError) {
        try self.init(key: WireGuardKey(base64Encoded: text))
    }

    init(key: WireGuardKey) throws(WireGuardKeyParsingError) {
        guard let agreementKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: key.bytes) else {
            throw .invalidLength
        }
        self.init(agreementKey: agreementKey)
    }

    private init(agreementKey: Curve25519.KeyAgreement.PrivateKey) {
        key = WireGuardKey(validatedBytes: Array(agreementKey.rawRepresentation))
        publicKey = PublicKey(key: WireGuardKey(validatedBytes: Array(agreementKey.publicKey.rawRepresentation)))
    }

    public static func generate() -> PrivateKey {
        PrivateKey(agreementKey: Curve25519.KeyAgreement.PrivateKey())
    }

    public var base64EncodedText: String {
        key.base64EncodedText
    }

    public var hexEncodedText: String {
        key.hexEncodedText
    }
}
