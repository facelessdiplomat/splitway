import CryptoKit

public struct PresharedKey: Sendable, Hashable {
    let key: WireGuardKey

    public init(base64Encoded text: String) throws(WireGuardKeyParsingError) {
        key = try WireGuardKey(base64Encoded: text)
    }

    private init(key: WireGuardKey) {
        self.key = key
    }

    public static func generate() -> PresharedKey {
        let randomKey = SymmetricKey(size: .bits256)
        return PresharedKey(key: WireGuardKey(validatedBytes: randomKey.withUnsafeBytes { Array($0) }))
    }

    public var base64EncodedText: String {
        key.base64EncodedText
    }

    public var hexEncodedText: String {
        key.hexEncodedText
    }
}
