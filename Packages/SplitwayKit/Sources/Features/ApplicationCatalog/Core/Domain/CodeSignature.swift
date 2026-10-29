public struct CodeSignature: Sendable, Hashable {
    public let signingIdentifier: String
    public let teamIdentifier: String?

    public init(signingIdentifier: String, teamIdentifier: String?) {
        self.signingIdentifier = signingIdentifier
        self.teamIdentifier = teamIdentifier
    }
}
