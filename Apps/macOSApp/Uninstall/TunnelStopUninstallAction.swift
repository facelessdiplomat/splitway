import Settings
import TunnelConnection

struct TunnelStopUninstallAction: UninstallAction {
    let step = UninstallStep.stopTunnel
    let deactivateTunnel: DeactivateTunnelUseCase

    func perform() async throws(UninstallStepFailure) {
        await deactivateTunnel.execute()
    }
}
