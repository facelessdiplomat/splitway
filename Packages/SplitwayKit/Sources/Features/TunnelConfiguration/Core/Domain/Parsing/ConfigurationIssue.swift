public struct ConfigurationIssue: Equatable, Sendable {
    public let line: Int?
    public let kind: ConfigurationIssueKind

    public init(line: Int?, kind: ConfigurationIssueKind) {
        self.line = line
        self.kind = kind
    }

    public var severity: ConfigurationIssueSeverity {
        kind.severity
    }
}
