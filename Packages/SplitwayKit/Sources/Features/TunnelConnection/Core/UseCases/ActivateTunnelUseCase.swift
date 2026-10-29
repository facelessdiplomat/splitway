import TunnelLibrary

public struct ActivateTunnelUseCase: Sendable {
    private let coordinator: ConnectionCoordinator

    public init(coordinator: ConnectionCoordinator) {
        self.coordinator = coordinator
    }

    public nonisolated(nonsending) func execute(_ tunnel: Tunnel) async throws(ConnectionFailure) {
        try await coordinator.activate(tunnel)
    }
}
