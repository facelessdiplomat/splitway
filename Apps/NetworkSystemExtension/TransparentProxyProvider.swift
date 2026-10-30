import Network
@preconcurrency import NetworkExtension
import PacketTunnel
import TransparentProxy
import TransparentProxyInfrastructure

final class TransparentProxyProvider: NETransparentProxyProvider, NEAppProxyUDPFlowHandling {
    private let composition = TransparentProxyComposition()

    override nonisolated(nonsending) func startProxy(options: [String: Any]? = nil) async throws {
        do {
            try await startSession()
        } catch {
            composition.log.record(.error, "Transparent proxy failed to start: \(error)")
            throw error
        }
    }

    override nonisolated(nonsending) func stopProxy(with reason: NEProviderStopReason) async {
        composition.log.record(.info, "Transparent proxy stopped by the system, reason \(reason.rawValue)")
        await composition.session.stop()
    }

    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        guard let streamFlow = flow as? NEAppProxyTCPFlow, let request = ProxiedFlowRequest(streamFlow) else {
            return false
        }
        return composition.session.handleStream(AppProxyStreamFlow(streamFlow), request: request)
    }

    func handleNewUDPFlow(_ flow: NEAppProxyUDPFlow, initialRemoteFlowEndpoint remoteEndpoint: Network.NWEndpoint)
        -> Bool
    {
        guard let request = ProxiedFlowRequest(flow, initialRemoteEndpoint: remoteEndpoint) else { return false }
        return composition.session.handleDatagrams(AppProxyDatagramFlow(flow), request: request)
    }

    private nonisolated(nonsending) func startSession() async throws {
        let tunnelProtocol = protocolConfiguration as? NETunnelProviderProtocol
        let tunnel = try await composition.loadActiveTunnel.execute(
            providerConfiguration: tunnelProtocol?.providerConfiguration
        )
        let plan = try await composition.session.start(tunnel)
        try await setTunnelNetworkSettings(TransparentProxyNetworkSettingsMapper.settings(for: plan))
        composition.log.record(.info, "Transparent proxy started")
    }
}
