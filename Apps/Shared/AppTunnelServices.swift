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

    init(configuration: AppConfiguration, log: LogRecorder) {
        #if os(macOS)
            let local = KeychainTunnelSecretStore()
            let channel = XPCExtensionSecretChannel(machServiceName: configuration.extensionMachServiceName)
            let mirrored = MirroredTunnelSecretStore(local: local, channel: channel) { error in
                log.record(.error, "The network extension did not get the tunnel configuration: \(error)")
            }
            let deliverSecret = DeliverTunnelSecretUseCase(secrets: local, channel: channel)
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
