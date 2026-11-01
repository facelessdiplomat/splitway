import Foundation
import Settings
import SettingsInfrastructure
import SettingsPresentation
import SystemExtension
import SystemExtensionInfrastructure

enum AppUninstall {
    @MainActor
    static func model(configuration: AppConfiguration, services: AppTunnelServices) -> UninstallModel {
        let actions: [any UninstallAction] = [
            TunnelStopUninstallAction(deactivateTunnel: services.connection.deactivateTunnel),
            VPNConfigurationUninstallAction(connection: services.connection),
            services.secretsUninstall,
            LoginItemUninstallAction(loginItem: MainAppLoginItem()),
            StoredDataUninstallAction(
                directories: [configuration.storageDirectory, configuration.logDirectory],
                preferencesDomain: Bundle.main.bundleIdentifier
            ),
            SystemExtensionUninstallAction(
                deactivateExtension: DeactivateSystemExtensionUseCase(
                    deactivator: OSSystemExtensionActivator(
                        extensionIdentifier: configuration.tunnelProviderBundleIdentifier
                    )
                )
            ),
        ]
        return UninstallModel(
            uninstall: UninstallUseCase(actions: actions),
            application: WorkspaceApplicationRemoval(applicationURL: Bundle.main.bundleURL)
        )
    }
}
