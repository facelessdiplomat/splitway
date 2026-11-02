import Foundation
import ProviderMessaging
import TunnelConnection
import TunnelLibrary

actor FileBackedSlotController: SystemTunnelController {
    private let preferencesFile: URL
    private var installed: TunnelIdentifier?
    private var status = SystemConnectionStatus.notConfigured

    init(preferencesFile: URL) {
        self.preferencesFile = preferencesFile
    }

    func installedTunnel() -> TunnelIdentifier? {
        installed
    }

    func currentStatus() -> SystemConnectionStatus {
        status
    }

    nonisolated func statusUpdates() -> AsyncStream<SystemConnectionStatus> {
        AsyncStream { continuation in continuation.finish() }
    }

    func lastDisconnectFailure() -> ConnectionFailure? {
        nil
    }

    func install(_ tunnel: Tunnel) throws(ConnectionFailure) {
        do {
            let providerConfiguration = try TunnelProviderConfigurationCodec.dictionary(
                for: TunnelProviderConfiguration(tunnelID: tunnel.id, routingPolicy: tunnel.routingPolicy)
            )
            let preferences: [String: Any] = [
                "providerConfiguration": providerConfiguration,
                "serverAddress": TunnelSlotDescription.serverAddress(for: tunnel),
            ]
            try FileManager.default.createDirectory(
                at: preferencesFile.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try PropertyListSerialization.data(fromPropertyList: preferences, format: .xml, options: 0)
                .write(to: preferencesFile)
        } catch {
            throw .systemConfigurationUnavailable
        }
        installed = tunnel.id
        status = .disconnected
    }

    func start() {
        status = .connected(since: Date())
    }

    func stop() {
        status = .disconnected
    }
}
