import Foundation

public struct ProxiedDatagram: Sendable, Hashable {
    public let payload: Data
    public let remoteEndpoint: FlowEndpoint

    public init(payload: Data, remoteEndpoint: FlowEndpoint) {
        self.payload = payload
        self.remoteEndpoint = remoteEndpoint
    }
}
