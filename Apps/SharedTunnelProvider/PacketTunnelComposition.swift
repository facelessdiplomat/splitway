import Diagnostics
import DiagnosticsInfrastructure
import Foundation
import PacketTunnel
import PacketTunnelInfrastructure
import SecretDeliveryInfrastructure
import TunnelCoreAdapter
import TunnelLibrary

struct PacketTunnelComposition: Sendable {
    private static let appGroupInfoKey = "SplitwayAppGroupIdentifier"
    private static let logsPath = "Library/Logs/Splitway"
    private static let fallbackSubsystem = "Splitway.PacketTunnel"

    let session: PacketTunnelSession
    let loadActiveTunnel: LoadActiveTunnelUseCase
    let log: LogRecorder

    init(bundle: Bundle = .main) {
        let subsystem = bundle.bundleIdentifier ?? Self.fallbackSubsystem
        let logStore = RotatingFileLogStore(directory: Self.logDirectory(in: bundle))
        log = LogRecorder(
            source: .tunnelExtension,
            store: logStore,
            systemLog: OSLogWriter(subsystem: subsystem, category: "Tunnel")
        )
        TunnelCoreLogRouting.route(
            to: LogRecorder(
                source: .engine, store: logStore, systemLog: OSLogWriter(subsystem: subsystem, category: "Engine"))
        )
        session = PacketTunnelSession(
            engine: TunnelCoreWireGuardEngine(),
            interfaceLocator: UtunDescriptorLocator(),
            endpointResolver: SystemEndpointResolver(),
            pathMonitor: NetworkPathObserver(),
            routingPlanner: PlanTunnelRoutingUseCase()
        )
        loadActiveTunnel = LoadActiveTunnelUseCase(secrets: Self.secretStore)
    }

    private static var secretStore: any TunnelSecretStore {
        SystemKeychainSecretStore()
    }

    static func logDirectory(in bundle: Bundle) -> URL {
        groupDirectory(at: logsPath, in: bundle)
    }

    private static func groupDirectory(at path: String, in bundle: Bundle) -> URL {
        let groupIdentifier = bundle.object(forInfoDictionaryKey: appGroupInfoKey) as? String
        let container = groupIdentifier.flatMap { identifier in
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
        }
        return (container ?? FileManager.default.temporaryDirectory).appending(path: path)
    }
}
