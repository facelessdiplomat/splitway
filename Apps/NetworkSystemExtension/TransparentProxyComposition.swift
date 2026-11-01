import Diagnostics
import DiagnosticsInfrastructure
import Foundation
import PacketTunnel
import PacketTunnelInfrastructure
import ProviderMessaging
import SecretDeliveryInfrastructure
import SharedKernel
import TransparentProxy
import TransparentProxyInfrastructure
import TunnelCoreAdapter

struct TransparentProxyComposition: Sendable {
    private static let fallbackSubsystem = "Splitway.TransparentProxy"
    private static let maintenanceInterval = Duration.seconds(5)

    let session: TransparentProxySession
    let loadActiveTunnel: LoadActiveTunnelUseCase
    let messageDispatcher: ProviderMessageDispatcher<TransparentProxyMessageHandler>
    let log: LogRecorder

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
                pathMTU: PrimaryInterfaceMTUReader()
            ),
            router: ProxiedFlowRouter(
                sourceResolver: SourceApplicationResolver(
                    reader: SecurityCodeIdentityReader(), ancestry: KernelProcessAncestryReader()),
                attribution: SuspiciousAttributionMonitor(log: SuspiciousAttributionLogRecorder(log: log)),
                environment: RelayEnvironment(
                    targetQueue: DispatchQueue(
                        label: "Splitway.ProxyRelays", qos: .userInitiated, attributes: .concurrent),
                    clock: SystemWallClock()
                )
            ),
            pathMonitor: NetworkPathObserver(),
            ticker: RepeatingTicker(interval: Self.maintenanceInterval),
            clock: SystemWallClock()
        )
        loadActiveTunnel = LoadActiveTunnelUseCase(secrets: SystemKeychainSecretStore())
        messageDispatcher = ProviderMessageDispatcher(handler: TransparentProxyMessageHandler(session: session))
    }
}
