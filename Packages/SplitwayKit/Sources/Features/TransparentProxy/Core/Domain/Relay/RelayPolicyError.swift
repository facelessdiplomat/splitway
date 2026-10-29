public enum RelayPolicyError: Error, Equatable, Sendable {
    case bufferSizeOutOfRange
    case nonPositiveTimeout
    case nonPositiveAssociationLimit
}
