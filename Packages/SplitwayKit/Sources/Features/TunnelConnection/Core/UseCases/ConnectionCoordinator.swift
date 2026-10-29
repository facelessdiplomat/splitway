import Synchronization
import TunnelLibrary

public final class ConnectionCoordinator: Sendable {
    private let controller: any SystemTunnelController
    private let latestIntent = Mutex<UInt64>(0)
    private let operations = ConnectionOperationQueue()

    public init(controller: any SystemTunnelController) {
        self.controller = controller
    }

    public nonisolated(nonsending) func activate(_ tunnel: Tunnel) async throws(ConnectionFailure) {
        let intent = registerIntent()
        await operations.enter()
        let outcome = await activationOutcome(of: tunnel, for: intent)
        await operations.leave()
        try outcome.get()
    }

    public nonisolated(nonsending) func deactivate() async {
        let intent = registerIntent()
        await operations.enter()
        if isLatest(intent) {
            await controller.stop()
        }
        await operations.leave()
    }

    private nonisolated(nonsending) func activationOutcome(
        of tunnel: Tunnel,
        for intent: UInt64
    ) async -> Result<Void, ConnectionFailure> {
        do {
            try await performActivation(of: tunnel, for: intent)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private nonisolated(nonsending) func performActivation(
        of tunnel: Tunnel,
        for intent: UInt64
    ) async throws(ConnectionFailure) {
        guard isLatest(intent) else { return }
        let status = await controller.currentStatus()
        let installedTunnel = await controller.installedTunnel()
        if installedTunnel == tunnel.id, status.isActive { return }
        if status.isActive {
            await controller.stop()
            guard isLatest(intent) else { return }
        }
        try await controller.install(tunnel)
        guard isLatest(intent) else { return }
        try await controller.start()
    }

    private func registerIntent() -> UInt64 {
        latestIntent.withLock { latest in
            latest += 1
            return latest
        }
    }

    private func isLatest(_ intent: UInt64) -> Bool {
        latestIntent.withLock { latest in latest == intent }
    }
}
