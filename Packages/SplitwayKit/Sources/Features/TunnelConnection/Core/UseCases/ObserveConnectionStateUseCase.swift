public struct ObserveConnectionStateUseCase: Sendable {
    private let controller: any SystemTunnelController

    public init(controller: any SystemTunnelController) {
        self.controller = controller
    }

    public func execute() -> AsyncStream<ConnectionState> {
        let controller = controller
        return AsyncStream { continuation in
            let observation = Task {
                var stateMachine = ConnectionStateMachine()
                for await status in controller.statusUpdates() {
                    let reason =
                        stateMachine.needsDisconnectReason(for: status)
                        ? await controller.lastDisconnectFailure()
                        : nil
                    continuation.yield(stateMachine.apply(status, disconnectReason: reason))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in observation.cancel() }
        }
    }
}
