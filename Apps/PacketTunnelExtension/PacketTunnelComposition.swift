import Diagnostics
import DiagnosticsInfrastructure
import Foundation
import PacketTunnel
import PacketTunnelInfrastructure
import ProviderMessaging
import TunnelCoreAdapter
import TunnelLibraryInfrastructure

struct PacketTunnelComposition: Sendable {
    private static let appGroupInfoKey = "SplitwayAppGroupIdentifier"
    private static let logsPath = "Library/Logs/Splitway"
    private static let fallbackSubsystem = "Splitway.PacketTunnel"

    let session: PacketTunnelSession
    let loadActiveTunnel: LoadActiveTunnelUseCase
    let messageDispatcher: ProviderMessageDispatcher
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
            pathMonitor: NetworkPathObserver()
        )
        loadActiveTunnel = LoadActiveTunnelUseCase(secrets: KeychainTunnelSecretStore())
        messageDispatcher = ProviderMessageDispatcher(handler: PacketTunnelMessageHandler(session: session))
    }

    private static func logDirectory(in bundle: Bundle) -> URL {
        let groupIdentifier = bundle.object(forInfoDictionaryKey: appGroupInfoKey) as? String
        let container = groupIdentifier.flatMap { identifier in
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
        }
        return (container ?? FileManager.default.temporaryDirectory).appending(path: logsPath)
    }
}
