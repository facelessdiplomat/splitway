import Foundation

public struct ApplicationIdentity: Sendable, Hashable {
    private static let pathSeparator: Character = "/"

    public let kind: ApplicationKind
    public let displayName: String
    public let path: String
    public let signingIdentifiers: [String]
    public let teamIdentifier: String?
    public let bundleVersion: String?

    public init(
        kind: ApplicationKind,
        displayName: String,
        path: String,
        signingIdentifiers: [String] = [],
        teamIdentifier: String? = nil,
        bundleVersion: String? = nil
    ) throws(ApplicationIdentityError) {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else { throw .emptyDisplayName }
        let pathWithoutTrailingSeparators = Self.removingTrailingSeparators(from: path)
        guard !pathWithoutTrailingSeparators.isEmpty else { throw .emptyPath }
        self.kind = kind
        self.displayName = displayName
        self.path = pathWithoutTrailingSeparators
        self.signingIdentifiers = Set(signingIdentifiers).sorted()
        self.teamIdentifier = teamIdentifier
        self.bundleVersion = bundleVersion
    }

    private static func removingTrailingSeparators(from path: String) -> String {
        var trimmed = Substring(path)
        while trimmed.last == pathSeparator {
            trimmed = trimmed.dropLast()
        }
        return String(trimmed)
    }
}
