public enum IPNetworkParsingError: Error, Equatable, Sendable {
    case invalidAddress(IPAddressParsingError)
    case malformedPrefixLength
    case prefixLengthOutOfRange
}
