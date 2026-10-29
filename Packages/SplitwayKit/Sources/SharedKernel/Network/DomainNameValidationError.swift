public enum DomainNameValidationError: Error, Equatable, Sendable {
    case empty
    case nonASCII
    case tooLong
    case emptyLabel
    case labelTooLong
    case invalidCharacter
    case hyphenAtLabelEdge
    case numericTopLevelLabel
}
