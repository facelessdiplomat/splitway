public struct SourceApplication: Sendable, Hashable {
    public let signingIdentifier: String?
    public let teamIdentifier: String?
    public let executablePath: String?
    public let unverifiedSigningIdentifier: String?

    public init(
        signingIdentifier: String?,
        teamIdentifier: String?,
        executablePath: String?,
        unverifiedSigningIdentifier: String? = nil
    ) {
        self.signingIdentifier = signingIdentifier
        self.teamIdentifier = teamIdentifier
        self.executablePath = executablePath
        self.unverifiedSigningIdentifier = unverifiedSigningIdentifier
    }
}
