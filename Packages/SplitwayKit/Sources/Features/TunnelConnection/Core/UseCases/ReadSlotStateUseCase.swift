public struct ReadSlotStateUseCase: Sendable {
    private let controller: any SystemTunnelController

    public init(controller: any SystemTunnelController) {
        self.controller = controller
    }

    public func execute() async -> SlotState {
        var stateMachine = ConnectionStateMachine()
        let connection = stateMachine.apply(await controller.currentStatus(), disconnectReason: nil)
        return SlotState(tunnelID: await controller.installedTunnel(), connection: connection)
    }
}
