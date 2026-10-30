public struct ProxiedFlowRequest: Sendable, Hashable {
    public let auditToken: AuditToken?
    public let remoteEndpoint: FlowEndpoint
    public let remoteHostname: String?

    public init(auditToken: AuditToken?, remoteEndpoint: FlowEndpoint, remoteHostname: String?) {
        self.auditToken = auditToken
        self.remoteEndpoint = remoteEndpoint
        self.remoteHostname = remoteHostname
    }
}
