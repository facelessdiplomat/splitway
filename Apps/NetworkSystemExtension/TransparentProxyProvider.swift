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
        let probe = composition.attributionProbe
        guard let streamFlow = flow as? NEAppProxyTCPFlow else {
            probe.record(probe.description(of: flow, transport: "other", remoteEndpoint: "none"), isHandled: false)
            return false
        }
        let description = probe.description(
            of: streamFlow, transport: "tcp", remoteEndpoint: "\(streamFlow.remoteFlowEndpoint)")
        guard let request = ProxiedFlowRequest(streamFlow) else {
            probe.record(description, isHandled: false)
            return false
        }
        let isHandled = composition.session.handleStream(AppProxyStreamFlow(streamFlow), request: request)
        probe.record(description, isHandled: isHandled)
        return isHandled
    }

    func handleNewUDPFlow(_ flow: NEAppProxyUDPFlow, initialRemoteFlowEndpoint remoteEndpoint: Network.NWEndpoint)
        -> Bool
    {
        let probe = composition.attributionProbe
        let description = probe.description(of: flow, transport: "udp", remoteEndpoint: "\(remoteEndpoint)")
        guard let request = ProxiedFlowRequest(flow, initialRemoteEndpoint: remoteEndpoint) else {
            probe.record(description, isHandled: false)
            return false
        }
        let isHandled = composition.session.handleDatagrams(AppProxyDatagramFlow(flow), request: request)
        probe.record(description, isHandled: isHandled)
        return isHandled
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
