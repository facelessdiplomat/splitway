public struct DeactivateTunnelUseCase: Sendable {
    private let coordinator: ConnectionCoordinator

    public init(coordinator: ConnectionCoordinator) {
        self.coordinator = coordinator
    }

    public nonisolated(nonsending) func execute() async {
        await coordinator.deactivate()
    }
}
