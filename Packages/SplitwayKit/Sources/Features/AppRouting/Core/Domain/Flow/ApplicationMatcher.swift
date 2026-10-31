public struct ApplicationMatcher: Sendable {
    private let teamsBySigningIdentifier: [String: Set<String?>]
    private let pathRules: [ApplicationPathRule]

    public init(_ applications: [ApplicationIdentity]) {
        var teamsBySigningIdentifier: [String: Set<String?>] = [:]
        for application in applications {
            for identifier in application.signingIdentifiers {
                teamsBySigningIdentifier[identifier, default: []].insert(application.teamIdentifier)
            }
        }
        self.teamsBySigningIdentifier = teamsBySigningIdentifier
        pathRules =
            applications
            .map { application in
                ApplicationPathRule(path: application.path, teamIdentifier: application.teamIdentifier)
            }
            .sorted { first, second in first.path < second.path }
    }

    public func matches(_ source: SourceApplication) -> Bool {
        matchesItself(source) || source.launchers.contains(where: matchesItself)
    }

    private func matchesItself(_ source: SourceApplication) -> Bool {
        if let identifier = source.signingIdentifier, let teams = teamsBySigningIdentifier[identifier] {
            return teams.contains(source.teamIdentifier)
        }
        if let executablePath = source.executablePath {
            return pathRules.contains { rule in
                rule.covers(executablePath)
                    && (rule.teamIdentifier == nil || rule.teamIdentifier == source.teamIdentifier)
            }
        }
        guard source.signingIdentifier == nil, let unverified = source.unverifiedSigningIdentifier else { return false }
        return teamsBySigningIdentifier[unverified] != nil
    }
}
