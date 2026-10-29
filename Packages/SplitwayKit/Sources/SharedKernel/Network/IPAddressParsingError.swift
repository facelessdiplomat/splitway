public enum IPAddressParsingError: Error, Equatable, Sendable {
    case empty
    case malformedIPv4
    case malformedIPv6
    case zoneIdentifierNotSupported
}
