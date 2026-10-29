public struct CodeIdentity: Sendable, Hashable {
    public let signingIdentifier: String?
    public let teamIdentifier: String?
    public let executablePath: String?
    public let isSignedByApple: Bool

    public init(signingIdentifier: String?, teamIdentifier: String?, executablePath: String?, isSignedByApple: Bool) {
        self.signingIdentifier = signingIdentifier
        self.teamIdentifier = teamIdentifier
        self.executablePath = executablePath
        self.isSignedByApple = isSignedByApple
    }
}
