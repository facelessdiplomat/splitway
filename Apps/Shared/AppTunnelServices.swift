import Diagnostics
import TunnelConnection
import TunnelConnectionInfrastructure
import TunnelLibrary
import TunnelLibraryInfrastructure

#if os(macOS)
    import SecretDelivery
    import SecretDeliveryInfrastructure
#endif

struct AppTunnelServices {
    let library: TunnelLibraryAssembly
    let connection: TunnelConnectionAssembly
    let serviceCatalog: AppServiceCatalog
    #if os(macOS)
        let secretsUninstall: TunnelSecretsUninstallAction
    #endif

    init(configuration: AppConfiguration, log: LogRecorder) {
        serviceCatalog = AppServiceCatalog(storageDirectory: configuration.storageDirectory)
        #if os(macOS)
            let local = KeychainTunnelSecretStore()
            let channel = XPCExtensionSecretChannel(machServiceName: configuration.extensionMachServiceName)
            let mirrored = MirroredTunnelSecretStore(local: local, channel: channel) { error in
                log.record(.error, "The network extension did not get the tunnel configuration: \(error)")
            }
            let deliverSecret = DeliverTunnelSecretUseCase(secrets: local, channel: channel)
            secretsUninstall = TunnelSecretsUninstallAction(local: local, extensionChannel: channel)
            library = TunnelLibraryAssembly(storageDirectory: configuration.storageDirectory, secrets: mirrored)
            connection = TunnelConnectionAssembly(
                providerBundleIdentifier: configuration.tunnelProviderBundleIdentifier
            ) { controller in
                SecretDeliveringTunnelController(controller: controller, deliverSecret: deliverSecret)
            }
        #else
            library = TunnelLibraryAssembly(storageDirectory: configuration.storageDirectory)
            connection = TunnelConnectionAssembly(
                providerBundleIdentifier: configuration.tunnelProviderBundleIdentifier
            )
        #endif
    }
}
