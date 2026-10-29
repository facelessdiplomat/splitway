import TunnelConnection

public struct TunnelConnectionActions: Sendable {
    let activateTunnel: ActivateTunnelUseCase
    let deactivateTunnel: DeactivateTunnelUseCase
    let observeConnection: ObserveConnectionStateUseCase

    public init(
        activateTunnel: ActivateTunnelUseCase,
        deactivateTunnel: DeactivateTunnelUseCase,
        observeConnection: ObserveConnectionStateUseCase
    ) {
        self.activateTunnel = activateTunnel
        self.deactivateTunnel = deactivateTunnel
        self.observeConnection = observeConnection
    }
}
