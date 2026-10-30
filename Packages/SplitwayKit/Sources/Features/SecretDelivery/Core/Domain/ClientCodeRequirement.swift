public struct ClientCodeRequirement: Sendable, Hashable {
    private static let teamIdentifierLength = 10
    private static let bundleIdentifierSeparator: Character = "."

    public let text: String

    public init(teamIdentifier: String, bundleIdentifier: String) throws(ClientCodeRequirementError) {
        guard Self.isValidTeamIdentifier(teamIdentifier) else { throw .invalidTeamIdentifier }
        guard Self.isValidBundleIdentifier(bundleIdentifier) else { throw .invalidBundleIdentifier }
        text = [
            "anchor apple generic",
            #"certificate leaf[subject.OU] = "\#(teamIdentifier)""#,
            #"identifier "\#(bundleIdentifier)""#,
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
