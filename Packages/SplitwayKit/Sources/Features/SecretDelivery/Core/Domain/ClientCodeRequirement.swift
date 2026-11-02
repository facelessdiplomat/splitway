public struct ClientCodeRequirement: Sendable, Hashable {
    private static let teamIdentifierLength = 10
    private static let bundleIdentifierSeparator: Character = "."
    private static let appStoreSignature = "certificate leaf[field.1.2.840.113635.100.6.1.9] exists"

    public let text: String

    public init(teamIdentifier: String, bundleIdentifier: String) throws(ClientCodeRequirementError) {
        guard Self.isValidTeamIdentifier(teamIdentifier) else { throw .invalidTeamIdentifier }
        guard Self.isValidBundleIdentifier(bundleIdentifier) else { throw .invalidBundleIdentifier }
        let teamSignature = #"certificate leaf[subject.OU] = "\#(teamIdentifier)""#
        text = [
            "anchor apple generic",
            #"identifier "\#(bundleIdentifier)""#,
            "(\(Self.appStoreSignature) or \(teamSignature))",
        ].joined(separator: " and ")
    }

    private static func isValidTeamIdentifier(_ text: String) -> Bool {
        text.count == teamIdentifierLength
            && text.unicodeScalars.allSatisfy { scalar in
                ("A"..."Z").contains(scalar) || ("0"..."9").contains(scalar)
            }
    }

    private static func isValidBundleIdentifier(_ text: String) -> Bool {
        let segments = text.split(separator: bundleIdentifierSeparator, omittingEmptySubsequences: false)
        return segments.allSatisfy { segment in
            !segment.isEmpty
                && segment.unicodeScalars.allSatisfy { scalar in
                    ("a"..."z").contains(scalar) || ("A"..."Z").contains(scalar) || ("0"..."9").contains(scalar)
                        || scalar == "-"
                }
        }
    }
}
