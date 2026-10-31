#if os(macOS)
    import Network
    import NetworkExtension
    import TransparentProxy

    extension ProxiedFlowRequest {
        public init?(_ flow: NEAppProxyTCPFlow) {
            guard let remoteEndpoint = FlowEndpoint(flow.remoteFlowEndpoint) else { return nil }
            self.init(
                auditToken: Self.auditToken(of: flow),
                remoteEndpoint: remoteEndpoint,
                remoteHostname: flow.remoteHostname,
                signingIdentifier: Self.signingIdentifier(of: flow)
            )
        }

        public init?(_ flow: NEAppProxyUDPFlow, initialRemoteEndpoint: Network.NWEndpoint) {
            guard let remoteEndpoint = FlowEndpoint(initialRemoteEndpoint) else { return nil }
            self.init(
                auditToken: Self.auditToken(of: flow),
                remoteEndpoint: remoteEndpoint,
                remoteHostname: flow.remoteHostname,
                signingIdentifier: Self.signingIdentifier(of: flow)
            )
        }

        private static func signingIdentifier(of flow: NEAppProxyFlow) -> String? {
            let identifier = flow.metaData.sourceAppSigningIdentifier
            return identifier.isEmpty ? nil : identifier
        }

        private static func auditToken(of flow: NEAppProxyFlow) -> AuditToken? {
            guard let token = flow.metaData.sourceAppAuditToken else { return nil }
            return try? AuditToken(bytes: Array(token))
        }
    }
#endif
