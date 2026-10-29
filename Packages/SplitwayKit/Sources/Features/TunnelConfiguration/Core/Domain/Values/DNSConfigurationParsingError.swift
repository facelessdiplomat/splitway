public enum DNSConfigurationParsingError: Error, Equatable, Sendable {
    case invalidEntry(String)
}
