import SecretDelivery
import Settings
import TunnelLibrary

struct TunnelSecretsUninstallAction: UninstallAction {
    let step = UninstallStep.removeSecrets
    let local: any ErasableTunnelSecretStore
    let extensionChannel: any ExtensionSecretChannel

    func perform() async throws(UninstallStepFailure) {
        var hasFailure = false
        do {
            try await local.deleteAllConfigurationTexts()
        } catch {
            hasFailure = true
        }
        do {
            try await extensionChannel.deliver(.removeAll)
        } catch {
            hasFailure = true
        }
        if hasFailure {
            throw UninstallStepFailure()
        }
    }
}
