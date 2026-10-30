import Foundation
import Security
import os

final class SystemKeychainSpikeService: NSObject, SecretsSpikeService {
    private static let sandboxContainerVariable = "APP_SANDBOX_CONTAINER_ID"

    private let logger = Logger(subsystem: SecretsSpikeNames.subsystem, category: "Extension")

    func describeProcess(reply: @escaping @Sendable (String) -> Void) {
        let isSandboxed = ProcessInfo.processInfo.environment[Self.sandboxContainerVariable] != nil
        reply("uid \(getuid()), euid \(geteuid()), sandboxed \(isSandboxed)")
    }

    func storeInSystemKeychain(_ secret: Data, reply: @escaping @Sendable (String) -> Void) {
        SecItemDelete(Self.itemQuery as CFDictionary)
        var attributes = Self.itemQuery
        attributes[kSecValueData] = secret
        let status = KeychainStatusDescription.of(SecItemAdd(attributes as CFDictionary, nil))
        logger.log("SP-5 variant B store: \(status, privacy: .public)")
        reply(status)
    }

    func loadFromSystemKeychain(reply: @escaping @Sendable (Data?, String) -> Void) {
        var query = Self.itemQuery
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = KeychainStatusDescription.of(SecItemCopyMatching(query as CFDictionary, &result))
        let secret = result as? Data
        let fingerprint = secret.map(SecretFingerprint.of) ?? "none"
        logger.log("SP-5 variant B load: \(status, privacy: .public), fingerprint \(fingerprint, privacy: .public)")
        reply(secret, status)
    }

    private static var itemQuery: [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: SecretsSpikeNames.keychainService,
            kSecAttrAccount: SecretsSpikeNames.keychainAccount,
            kSecUseDataProtectionKeychain: false,
        ]
    }
}
