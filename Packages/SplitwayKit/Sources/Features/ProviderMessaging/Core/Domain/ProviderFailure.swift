public enum ProviderFailure: String, Sendable, Hashable, Codable {
    case unsupportedProtocolVersion
    case malformedRequest
    case tunnelNotRunning
    case routingPolicyRejected
    case internalFailure
}
