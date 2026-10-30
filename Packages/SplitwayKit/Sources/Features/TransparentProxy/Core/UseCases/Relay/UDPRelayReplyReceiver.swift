import TunnelEngine

final class UDPRelayReplyReceiver: UserspaceConnectionReceiver {
    private let relay: UDPFlowRelay
    private let endpoint: FlowEndpoint
    private let association: any UserspaceConnection

    init(relay: UDPFlowRelay, endpoint: FlowEndpoint, association: any UserspaceConnection) {
        self.relay = relay
        self.endpoint = endpoint
        self.association = association
    }

    func receive(_ bytes: UnsafeRawBufferPointer) {
        relay.deliverReply(bytes, from: endpoint, through: association)
    }

    func finish(_ error: UserspaceNetworkError?) {}
}
