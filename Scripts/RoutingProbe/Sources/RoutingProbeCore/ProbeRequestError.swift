public enum ProbeRequestError: Error, Equatable, Sendable {
    case unknownMode(String)
    case missingAddress
    case invalidAddress(String)
    case invalidCount(String)
}
