extension PublicKey: CustomStringConvertible {
    public var description: String {
        base64EncodedText
    }
}
