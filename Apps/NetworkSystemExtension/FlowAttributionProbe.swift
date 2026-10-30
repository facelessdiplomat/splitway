import Diagnostics
@preconcurrency import NetworkExtension
import TransparentProxy
import TransparentProxyInfrastructure

struct FlowAttributionProbe: Sendable {
    private let log: LogRecorder
    private let reader = SecurityCodeIdentityReader()

    init(log: LogRecorder) {
        self.log = log
    }

    func description(of flow: NEAppProxyFlow, transport: String, remoteEndpoint: String) -> String {
        let metadata = flow.metaData
        let token = metadata.sourceAppAuditToken.flatMap { token in try? AuditToken(bytes: Array(token)) }
        let identity = token.flatMap { token in try? reader.codeIdentity(of: token) }
        let fields = [
            "transport=\(transport)",
            "pid=\(token.map { token in String(token.processInstance.identifier) } ?? "none")",
            "metadataIdentifier=\(metadata.sourceAppSigningIdentifier)",
            "processIdentifier=\(identity?.signingIdentifier ?? "none")",
            "team=\(identity?.teamIdentifier ?? "none")",
            "apple=\(identity?.isSignedByApple == true)",
            "path=\(identity?.executablePath ?? "none")",
            "hostname=\(flow.remoteHostname ?? "none")",
            "remote=\(remoteEndpoint)",
        ]
        return fields.joined(separator: " ")
    }

    func record(_ description: String, isHandled: Bool) {
        log.record(.info, "SP-2 flow \(description) handled=\(isHandled)")
    }
}
