import TunnelConnection
import TunnelLibrary

public struct TunnelEditorActions: Sendable {
    let createTunnel: CreateTunnelUseCase
    let updateTunnel: UpdateTunnelUseCase
    let renameTunnel: RenameTunnelUseCase
    let activityProbe: any TunnelActivityProbe
    let activateTunnel: ActivateTunnelUseCase
    let deactivateTunnel: DeactivateTunnelUseCase
    let applyRoutingPolicy: ApplyRoutingPolicyUseCase

    public init(
        createTunnel: CreateTunnelUseCase,
        updateTunnel: UpdateTunnelUseCase,
        renameTunnel: RenameTunnelUseCase,
        activityProbe: any TunnelActivityProbe,
        activateTunnel: ActivateTunnelUseCase,
        deactivateTunnel: DeactivateTunnelUseCase,
        applyRoutingPolicy: ApplyRoutingPolicyUseCase
    ) {
        self.createTunnel = createTunnel
        self.updateTunnel = updateTunnel
        self.renameTunnel = renameTunnel
        self.activityProbe = activityProbe
        self.activateTunnel = activateTunnel
        self.deactivateTunnel = deactivateTunnel
        self.applyRoutingPolicy = applyRoutingPolicy
    }
}
