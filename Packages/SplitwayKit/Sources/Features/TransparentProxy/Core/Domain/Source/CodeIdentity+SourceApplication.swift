import AppRouting

extension CodeIdentity {
    var sourceApplication: SourceApplication {
        SourceApplication(
            signingIdentifier: hasVerifiableSigningIdentifier ? signingIdentifier : nil,
            teamIdentifier: teamIdentifier,
            executablePath: executablePath
        )
    }

    private var hasVerifiableSigningIdentifier: Bool {
        teamIdentifier != nil || isSignedByApple
    }
}
