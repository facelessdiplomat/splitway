public enum TunnelNameError: Error, Equatable, Sendable {
    case empty
    case tooLong
    case containsControlCharacters
}
