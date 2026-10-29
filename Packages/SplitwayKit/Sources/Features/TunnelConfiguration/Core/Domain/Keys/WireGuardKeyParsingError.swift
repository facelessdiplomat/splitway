public enum WireGuardKeyParsingError: Error, Equatable, Sendable {
    case malformedBase64
    case malformedHex
    case invalidLength
}
