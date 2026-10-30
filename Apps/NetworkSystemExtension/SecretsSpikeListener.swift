import Foundation
import SecretDelivery
import os

final class SecretsSpikeListener: NSObject, NSXPCListenerDelegate {
    private static let teamIdentifierSeparator: Character = "."

    private let listener: NSXPCListener
    private let logger = Logger(subsystem: SecretsSpikeNames.subsystem, category: "Extension")

    init?(bundle: Bundle) {
        guard
            let networkExtension = bundle.object(forInfoDictionaryKey: SecretsSpikeNames.networkExtensionKey)
                as? [String: Any],
            let machServiceName = networkExtension[SecretsSpikeNames.machServiceNameKey] as? String,
            let extensionIdentifier = bundle.bundleIdentifier
        else { return nil }
        listener = NSXPCListener(machServiceName: machServiceName)
        super.init()
        listener.delegate = self
        let teamIdentifier = String(machServiceName.prefix { character in character != Self.teamIdentifierSeparator })
        let suffixLength = SecretsSpikeNames.extensionIdentifierSuffix.count
        let applicationIdentifier = String(extensionIdentifier.dropLast(suffixLength))
        requireClient(teamIdentifier: teamIdentifier, applicationIdentifier: applicationIdentifier)
    }

    func start() {
        listener.resume()
        logger.log("SP-5 listener started")
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.exportedInterface = NSXPCInterface(with: (any SecretsSpikeService).self)
        connection.exportedObject = SystemKeychainSpikeService()
        connection.resume()
        logger.log("SP-5 accepted a client with pid \(connection.processIdentifier)")
        return true
    }

    private func requireClient(teamIdentifier: String, applicationIdentifier: String) {
        do {
            let requirement = try ClientCodeRequirement(
                teamIdentifier: teamIdentifier,
                bundleIdentifier: applicationIdentifier
            )
            listener.setConnectionCodeSigningRequirement(requirement.text)
            logger.log("SP-5 client requirement: \(requirement.text, privacy: .public)")
        } catch {
            logger.error("SP-5 client requirement rejected: \(String(describing: error), privacy: .public)")
        }
    }
}
