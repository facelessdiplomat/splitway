import Foundation

public struct ApplicationIdentity: Sendable, Hashable {
    public let kind: ApplicationKind
    public let displayName: String
    public let path: String
    public let signingIdentifiers: [String]
    public let teamIdentifier: String?

    public init(
        kind: ApplicationKind,
        displayName: String,
        path: String,
        signingIdentifiers: [String] = [],
        teamIdentifier: String? = nil
    ) throws(ApplicationIdentityError) {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else { throw .emptyDisplayName }
        guard !path.isEmpty else { throw .emptyPath }
        self.kind = kind
        self.displayName = displayName
        self.path = path
        self.signingIdentifiers = Set(signingIdentifiers).sorted()
        self.teamIdentifier = teamIdentifier
    }
}
