import Foundation
import NetworkExtension
import ProviderMessaging
import SharedKernel
import TunnelConnection
import TunnelLibrary

public actor PacketTunnelSlotController: SystemTunnelController {
    private static let slotName = "Splitway"
    private static let disconnectionTimeout = Duration.seconds(10)

    private let providerBundleIdentifier: String
    private let clock: any WallClock
    private let statusStream: AsyncStream<SystemConnectionStatus>
    private let statusContinuation: AsyncStream<SystemConnectionStatus>.Continuation
    private var manager: NETunnelProviderManager?
    private var hasLoadedManager = false
    private var statusObserver: (any NSObjectProtocol)?
    private var disconnectionWaiters: [CheckedContinuation<Void, Never>] = []

    public init(providerBundleIdentifier: String, clock: any WallClock = SystemWallClock()) {
        self.providerBundleIdentifier = providerBundleIdentifier
        self.clock = clock
        (statusStream, statusContinuation) = AsyncStream.makeStream()
    }

    isolated deinit {
        if let statusObserver {
            NotificationCenter.default.removeObserver(statusObserver)
        }
    }

    public func installedTunnel() async -> TunnelIdentifier? {
        guard let tunnelProtocol = await loadedManager()?.protocolConfiguration as? NETunnelProviderProtocol else {
            return nil
        }
        return try? TunnelProviderConfigurationCodec.configuration(from: tunnelProtocol.providerConfiguration).tunnelID
    }

    public func currentStatus() async -> SystemConnectionStatus {
        guard let connection = await loadedManager()?.connection else { return .notConfigured }
        return status(of: connection)
    }

    public nonisolated func statusUpdates() -> AsyncStream<SystemConnectionStatus> {
        Task { await self.startPublishingStatus() }
        return statusStream
    }

    public func lastDisconnectFailure() async -> ConnectionFailure? {
        guard let connection = await loadedManager()?.connection else { return nil }
        do {
            try await connection.fetchLastDisconnectError()
            return nil
        } catch {
            return VPNErrorMapping.failureOfDisconnect(error)
        }
    }

    public func install(_ tunnel: Tunnel) async throws(ConnectionFailure) {
        let tunnelProtocol = NETunnelProviderProtocol()
        tunnelProtocol.providerBundleIdentifier = providerBundleIdentifier
        tunnelProtocol.serverAddress = TunnelSlotDescription.serverAddress(for: tunnel)
        do {
            tunnelProtocol.providerConfiguration = try TunnelProviderConfigurationCodec.dictionary(
                for: TunnelProviderConfiguration(tunnelID: tunnel.id, routingPolicy: tunnel.routingPolicy)
            )
        } catch {
            throw .systemConfigurationUnavailable
        }
        let slot = await loadedManager() ?? NETunnelProviderManager()
        slot.protocolConfiguration = tunnelProtocol
        slot.localizedDescription = Self.slotName
        slot.isEnabled = true
        do {
            try await slot.saveToPreferences()
            try await slot.loadFromPreferences()
        } catch {
            throw VPNErrorMapping.failureOfSaving(error)
        }
        manager = slot
        startPublishingStatus()
    }

    public func start() async throws(ConnectionFailure) {
        guard let connection = await loadedManager()?.connection else { throw .systemConfigurationUnavailable }
        do {
            try connection.startVPNTunnel()
        } catch {
            throw VPNErrorMapping.failureOfStarting(error)
        }
    }

    public func stop() async {
        guard let connection = await loadedManager()?.connection, !Self.hasEnded(connection.status) else { return }
        startPublishingStatus()
        connection.stopVPNTunnel()
        await waitUntilDisconnected()
    }

    private func loadedManager() async -> NETunnelProviderManager? {
        if !hasLoadedManager {
            hasLoadedManager = true
            let savedManagers = (try? await NETunnelProviderManager.loadAllFromPreferences()) ?? []
            manager = savedManagers.first { savedManager in
                (savedManager.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier
                    == providerBundleIdentifier
            }
        }
        return manager
    }

    private func startPublishingStatus() {
        guard statusObserver == nil else { return }
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let connection = notification.object as? NEVPNConnection else { return }
            let connectionIdentifier = ObjectIdentifier(connection)
            Task { await self?.connectionStatusDidChange(connectionIdentifier) }
        }
        if let connection = manager?.connection {
            statusContinuation.yield(status(of: connection))
        }
    }

    private func connectionStatusDidChange(_ connectionIdentifier: ObjectIdentifier) {
        guard let connection = manager?.connection, ObjectIdentifier(connection) == connectionIdentifier else { return }
        statusContinuation.yield(status(of: connection))
        if Self.hasEnded(connection.status) {
            resumeDisconnectionWaiters()
        }
    }

    private func waitUntilDisconnected() async {
        let timeout = Task { [weak self] in
            try? await Task.sleep(for: Self.disconnectionTimeout)
            await self?.resumeDisconnectionWaiters()
        }
        await withCheckedContinuation { continuation in disconnectionWaiters.append(continuation) }
        timeout.cancel()
    }

    private func resumeDisconnectionWaiters() {
        for waiter in disconnectionWaiters {
            waiter.resume()
        }
        disconnectionWaiters.removeAll()
    }

    private func status(of connection: NEVPNConnection) -> SystemConnectionStatus {
        VPNStatusMapping.status(
            of: connection.status,
            connectedDate: connection.connectedDate,
            fallbackConnectedDate: clock.now()
        )
    }

    private static func hasEnded(_ status: NEVPNStatus) -> Bool {
        status == .disconnected || status == .invalid
    }
}
