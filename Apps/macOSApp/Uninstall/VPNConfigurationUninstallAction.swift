import Settings
import TunnelConnectionInfrastructure

struct VPNConfigurationUninstallAction: UninstallAction {
    let step = UninstallStep.removeVPNConfigurations
    let connection: TunnelConnectionAssembly

    func perform() async throws(UninstallStepFailure) {
        do {
            try await connection.removeSystemConfigurations()
        } catch {
            throw UninstallStepFailure()
        }
    }
}
