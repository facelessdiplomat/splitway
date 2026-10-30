import Foundation
import NetworkExtension
import Security
import os

@MainActor
enum SecretsSpikeRunner {
    private static let systemExtensionsDirectory = "Contents/Library/SystemExtensions"
    private static let systemExtensionSuffix = ".systemextension"
    private static let logger = Logger(subsystem: SecretsSpikeNames.subsystem, category: "Application")

    static func runIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains(SecretsSpikeNames.launchArgument) else { return }
        Task {
            await run()
        }
    }

    private static var extensionIdentifier: String {
        (Bundle.main.bundleIdentifier ?? "") + SecretsSpikeNames.extensionIdentifierSuffix
    }

    private static func run() async {
        let secret = Data(UUID().uuidString.utf8)
        logger.log("SP-5 dummy secret fingerprint \(SecretFingerprint.of(secret), privacy: .public)")
        deliverOverConnection(secret)
        await startTunnel(carrying: secret)
    }

    private static var extensionMachServiceName: String? {
        let bundleURL = Bundle.main.bundleURL.appending(
            path: "\(systemExtensionsDirectory)/\(extensionIdentifier)\(systemExtensionSuffix)")
        let networkExtension =
            Bundle(url: bundleURL)?.object(forInfoDictionaryKey: SecretsSpikeNames.networkExtensionKey)
            as? [String: Any]
        return networkExtension?[SecretsSpikeNames.machServiceNameKey] as? String
    }

    private static func deliverOverConnection(_ secret: Data) {
        let logger = Self.logger
        guard let machServiceName = extensionMachServiceName else {
            logger.error("SP-5 no Mach service name in the extension bundle")
            return
        }
        let connection = NSXPCConnection(machServiceName: machServiceName, options: [])
        connection.remoteObjectInterface = NSXPCInterface(with: (any SecretsSpikeService).self)
        connection.resume()
        let proxy = connection.remoteObjectProxyWithErrorHandler { error in
            logger.error("SP-5 connection error: \(String(describing: error), privacy: .public)")
        }
        guard let service = proxy as? any SecretsSpikeService else {
            logger.error("SP-5 no service proxy")
            return
        }
        service.describeProcess { description in
            logger.log("SP-5 extension process: \(description, privacy: .public)")
        }
        service.storeInSystemKeychain(secret) { status in
            logger.log("SP-5 variant B store reply: \(status, privacy: .public)")
        }
        service.loadFromSystemKeychain { loaded, status in
            let fingerprint = loaded.map(SecretFingerprint.of) ?? "none"
            logger.log(
                "SP-5 variant B load reply: \(status, privacy: .public), fingerprint \(fingerprint, privacy: .public)"
            )
        }
    }

    private static func startTunnel(carrying secret: Data) async {
        let reference = storeInUserKeychain(secret)
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            let identifier = extensionIdentifier
            let manager =
                managers.first { manager in
                    (manager.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == identifier
                } ?? NETunnelProviderManager()
            let configuration = NETunnelProviderProtocol()
            configuration.providerBundleIdentifier = extensionIdentifier
            configuration.serverAddress = SecretsSpikeNames.tunnelDescription
            configuration.passwordReference = reference
            configuration.providerConfiguration = [
                SecretsSpikeNames.providerConfigurationKey: String(bytes: secret, encoding: .utf8) ?? ""
            ]
            manager.protocolConfiguration = configuration
            manager.localizedDescription = SecretsSpikeNames.tunnelDescription
            manager.isEnabled = true
            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()
            try manager.connection.startVPNTunnel()
            logger.log("SP-5 tunnel start requested")
        } catch {
            logger.error("SP-5 tunnel start failed: \(String(describing: error), privacy: .public)")
        }
    }

    private static func storeInUserKeychain(_ secret: Data) -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: SecretsSpikeNames.keychainService,
            kSecAttrAccount: SecretsSpikeNames.keychainAccount,
            kSecUseDataProtectionKeychain: true,
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData] = secret
        attributes[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        attributes[kSecReturnPersistentRef] = true
        var result: CFTypeRef?
        let status = KeychainStatusDescription.of(SecItemAdd(attributes as CFDictionary, &result))
        logger.log("SP-5 variant A store in the user keychain: \(status, privacy: .public)")
        return result as? Data
    }
}
