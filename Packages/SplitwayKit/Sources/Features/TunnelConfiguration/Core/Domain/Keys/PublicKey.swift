public struct PublicKey: Sendable, Hashable {
    let key: WireGuardKey

    init(key: WireGuardKey) {
        self.key = key
    }

    public init(base64Encoded text: String) throws(WireGuardKeyParsingError) {
        key = try WireGuardKey(base64Encoded: text)
    }

    public init(hexEncoded text: String) throws(WireGuardKeyParsingError) {
        key = try WireGuardKey(hexEncoded: text)
    }

    public var base64EncodedText: String {
        key.base64EncodedText
    }

    public var hexEncodedText: String {
        key.hexEncodedText
    }
}
