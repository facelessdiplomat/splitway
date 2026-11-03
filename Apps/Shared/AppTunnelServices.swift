import Diagnostics
import SecretDelivery
import SecretDeliveryInfrastructure
import TunnelConnection
import TunnelConnectionInfrastructure
import TunnelLibrary
import TunnelLibraryInfrastructure

struct AppTunnelServices {
    let library: TunnelLibraryAssembly
    let connection: TunnelConnectionAssembly
    let secretsUninstall: TunnelSecretsUninstallAction

    init(configuration: AppConfiguration, log: LogRecorder) {
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
    }
}
