import Settings
import SystemExtension

struct SystemExtensionUninstallAction: UninstallAction {
    let step = UninstallStep.deactivateSystemExtension
    let deactivateExtension: DeactivateSystemExtensionUseCase

    func perform() async throws(UninstallStepFailure) {
        do {
            _ = try await deactivateExtension.execute()
        } catch {
            throw UninstallStepFailure()
        }
    }
}
