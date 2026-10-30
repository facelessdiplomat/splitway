import Diagnostics
import DiagnosticsInfrastructure
import Foundation
import Network
@preconcurrency import NetworkExtension

final class DNSProxyProvider: NEDNSProxyProvider, NEAppProxyUDPFlowHandling {
    private static let fallbackSubsystem = "Splitway.DNSProxy"

    private let log = LogRecorder(
        source: .tunnelExtension,
        store: RotatingFileLogStore(directory: PacketTunnelComposition.logDirectory(in: .main)),
        systemLog: OSLogWriter(subsystem: Bundle.main.bundleIdentifier ?? fallbackSubsystem, category: "DNSProxy")
    )
    private let queue = DispatchQueue(label: "Splitway.DNSProxySpike")

    override nonisolated(nonsending) func startProxy(options: [String: Any]? = nil) async throws {
        let servers = systemDNSSettings?.flatMap(\.servers) ?? []
        log.record(
            .info,
            "SP-9 dns proxy started pid=\(ProcessInfo.processInfo.processIdentifier) systemDNS=\(servers)"
        )
    }

    override nonisolated(nonsending) func stopProxy(with reason: NEProviderStopReason) async {
        log.record(.info, "SP-9 dns proxy stopped reason=\(reason.rawValue)")
    }

    override func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        let probe = FlowAttributionProbe(log: log)
        let description = probe.description(of: flow, transport: "tcp", remoteEndpoint: "unknown")
        log.record(.info, "SP-9 dns flow \(description) handled=false")
        return false
    }

    func handleNewUDPFlow(_ flow: NEAppProxyUDPFlow, initialRemoteFlowEndpoint remoteEndpoint: Network.NWEndpoint)
        -> Bool
    {
        let probe = FlowAttributionProbe(log: log)
        let description = probe.description(of: flow, transport: "udp", remoteEndpoint: "\(remoteEndpoint)")
        log.record(
            .info, "SP-9 dns flow \(description) providerPid=\(ProcessInfo.processInfo.processIdentifier) handled=true")
        DNSDatagramForwarder(flow, queue: queue).start()
        return true
    }
}
