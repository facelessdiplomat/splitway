import Diagnostics
import DiagnosticsInfrastructure
import Foundation
import PacketTunnel
import PacketTunnelInfrastructure
import SecretDeliveryInfrastructure
import SharedKernel
import TransparentProxy
import TransparentProxyInfrastructure
import TunnelCoreAdapter

struct TransparentProxyComposition: Sendable {
    private static let fallbackSubsystem = "Splitway.TransparentProxy"

    let session: TransparentProxySession
    let loadActiveTunnel: LoadActiveTunnelUseCase
    let log: LogRecorder
    let attributionProbe: FlowAttributionProbe

    init(bundle: Bundle = .main) {
        log = LogRecorder(
            source: .tunnelExtension,
            store: RotatingFileLogStore(directory: PacketTunnelComposition.logDirectory(in: bundle)),
            systemLog: OSLogWriter(subsystem: bundle.bundleIdentifier ?? Self.fallbackSubsystem, category: "Proxy")
        )
        session = TransparentProxySession(
            starter: TransparentProxyStarter(
                engine: TunnelCoreUserspaceNetworkEngine(),
                endpointResolution: ResolveTunnelEndpointsUseCase(resolver: SystemEndpointResolver()),
                registry: TunnelRuntimeRegistry()
            ),
            router: ProxiedFlowRouter(
                sourceResolver: SourceApplicationResolver(reader: SecurityCodeIdentityReader()),
                attribution: SuspiciousAttributionMonitor(log: SuspiciousAttributionLogRecorder(log: log)),
                environment: RelayEnvironment(
                    targetQueue: DispatchQueue(
                        label: "Splitway.ProxyRelays", qos: .userInitiated, attributes: .concurrent),
                    clock: SystemWallClock()
                )
            ),
            pathMonitor: NetworkPathObserver()
        )
        loadActiveTunnel = LoadActiveTunnelUseCase(secrets: SystemKeychainSecretStore())
        attributionProbe = FlowAttributionProbe(log: log)
    }
}
