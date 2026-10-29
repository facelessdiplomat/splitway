public struct SourceApplication: Sendable, Hashable {
    public let signingIdentifier: String?
    public let teamIdentifier: String?
    public let executablePath: String?

    public init(signingIdentifier: String?, teamIdentifier: String?, executablePath: String?) {
        self.signingIdentifier = signingIdentifier
        self.teamIdentifier = teamIdentifier
        self.executablePath = executablePath
    }
}
