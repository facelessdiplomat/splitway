import TunnelConfiguration
import TunnelLibrary

public struct ImportPreviewCandidate: Sendable, Equatable {
    public let source: ImportSource
    public let proposedName: TunnelName
    public let uniqueName: TunnelName
    public let configuration: TunnelConfiguration?
    public let issues: [ConfigurationIssue]
    public let alreadyImportedAs: TunnelName?

    public var isImportable: Bool {
        configuration != nil
    }

    public var hasNameConflict: Bool {
        uniqueName != proposedName
    }

    public var errors: [ConfigurationIssue] {
        issues.filter { issue in issue.severity == .error }
    }

    public var warnings: [ConfigurationIssue] {
        issues.filter { issue in issue.severity == .warning }
    }
}
