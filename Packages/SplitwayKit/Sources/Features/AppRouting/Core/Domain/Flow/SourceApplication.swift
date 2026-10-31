public struct SourceApplication: Sendable, Hashable {
    public let signingIdentifier: String?
    public let teamIdentifier: String?
    public let executablePath: String?
    public let unverifiedSigningIdentifier: String?
    public let launchers: [SourceApplication]

    public init(
        signingIdentifier: String?,
        teamIdentifier: String?,
        executablePath: String?,
        unverifiedSigningIdentifier: String? = nil,
        launchers: [SourceApplication] = []
    ) {
        self.signingIdentifier = signingIdentifier
        self.teamIdentifier = teamIdentifier
        self.executablePath = executablePath
        self.unverifiedSigningIdentifier = unverifiedSigningIdentifier
        self.launchers = launchers
    }

    public func launched(by launchers: [SourceApplication]) -> SourceApplication {
        SourceApplication(
            signingIdentifier: signingIdentifier,
            teamIdentifier: teamIdentifier,
            executablePath: executablePath,
            unverifiedSigningIdentifier: unverifiedSigningIdentifier,
            launchers: launchers
        )
    }
}
