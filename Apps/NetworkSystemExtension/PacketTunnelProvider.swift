import NetworkExtension

final class PacketTunnelProvider: NEPacketTunnelProvider {
    override nonisolated(nonsending) func startTunnel(options: [String: NSObject]?) async throws {
        throw ProviderStartFailure.tunnelEngineNotIntegrated
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {}
}
