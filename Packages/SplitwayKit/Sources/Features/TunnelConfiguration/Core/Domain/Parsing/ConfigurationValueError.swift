import SharedKernel

public enum ConfigurationValueError: Error, Equatable, Sendable {
    case key(WireGuardKeyParsingError)
    case network(IPNetworkParsingError)
    case port(NetworkPortValidationError)
    case mtu(MTUValidationError)
    case persistentKeepalive(PersistentKeepaliveValidationError)
    case endpoint(EndpointParsingError)
    case dns(DNSConfigurationParsingError)
}
