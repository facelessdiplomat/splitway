public struct WgQuickParsingResult: Sendable {
    public let configuration: TunnelConfiguration?
    public let issues: [ConfigurationIssue]

    init(configuration: TunnelConfiguration?, issues: [ConfigurationIssue]) {
        self.configuration = configuration
        self.issues = issues
    }

    public var errors: [ConfigurationIssue] {
        issues.filter { issue in issue.severity == .error }
    }

    public var warnings: [ConfigurationIssue] {
        issues.filter { issue in issue.severity == .warning }
    }
}
