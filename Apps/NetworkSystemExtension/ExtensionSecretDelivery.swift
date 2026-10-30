import Foundation
import SecretDelivery
import SecretDeliveryInfrastructure

struct ExtensionSecretDelivery {
    private static let networkExtensionKey = "NetworkExtension"
    private static let machServiceNameKey = "NEMachServiceName"
    private static let teamIdentifierKey = "SplitwayTeamIdentifier"
    private static let clientBundleIdentifierKey = "SplitwayClientBundleIdentifier"

    private let listener: SecretDeliveryListener

    init?(bundle: Bundle) {
        guard
            let networkExtension = bundle.object(forInfoDictionaryKey: Self.networkExtensionKey) as? [String: Any],
            let machServiceName = networkExtension[Self.machServiceNameKey] as? String,
            let teamIdentifier = bundle.object(forInfoDictionaryKey: Self.teamIdentifierKey) as? String,
            let clientIdentifier = bundle.object(forInfoDictionaryKey: Self.clientBundleIdentifierKey) as? String,
            let requirement = try? ClientCodeRequirement(
                teamIdentifier: teamIdentifier,
                bundleIdentifier: clientIdentifier
            )
        else { return nil }
        listener = SecretDeliveryListener(
            machServiceName: machServiceName,
            store: SystemKeychainSecretStore(),
            clientRequirement: requirement
        )
    }

    func start() {
        listener.start()
    }
}
