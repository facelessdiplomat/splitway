import SharedKernel

public enum EndpointParsingError: Error, Equatable, Sendable {
    case missingPort
    case unbracketedIPv6
    case invalidHost
    case invalidPort(NetworkPortValidationError)
}
