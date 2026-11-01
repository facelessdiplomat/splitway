public struct ServiceIdentifier: Sendable, Hashable {
    private static let maximumLength = 64
    private static let separator: Character = "-"

    private let value: String

    public init(_ value: String) throws(ServiceIdentifierError) {
        guard (1...Self.maximumLength).contains(value.count),
            value.allSatisfy(Self.isAllowed),
            value.first != Self.separator,
            value.last != Self.separator
        else { throw .malformed }
        self.value = value
    }

    init(validatedValue value: String) {
        self.value = value
    }

    private static func isAllowed(_ character: Character) -> Bool {
        character.isASCII && (character.isLowercase || character.isNumber || character == separator)
    }

    var text: String {
        value
    }
}
