public struct ProxiedFlowRequest: Sendable, Hashable {
    public let auditToken: AuditToken?
    public let remoteEndpoint: FlowEndpoint
    public let remoteHostname: String?
    public let signingIdentifier: String?

    public init(
        auditToken: AuditToken?,
        remoteEndpoint: FlowEndpoint,
        remoteHostname: String?,
        signingIdentifier: String? = nil
    ) {
        self.auditToken = auditToken
        self.remoteEndpoint = remoteEndpoint
        self.remoteHostname = remoteHostname
        self.signingIdentifier = signingIdentifier
    }
}
