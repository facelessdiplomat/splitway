import Foundation
import Security
import TunnelLibrary

struct SystemKeychainItem: Sendable {
    private static let maximumDeletions = 10_000

    let service: String
    let account: String

    static func deleteAll(service: String) throws(TunnelStorageError) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecUseDataProtectionKeychain: false,
        ]
        for _ in 0..<maximumDeletions {
            switch SecItemDelete(query as CFDictionary) {
            case errSecSuccess: continue
            case errSecItemNotFound: return
            default: throw .unavailable
            }
        }
        throw .unavailable
    }

    func loadText() throws(TunnelStorageError) -> String {
        var lookup = query
        lookup[kSecReturnData] = true
        lookup[kSecMatchLimit] = kSecMatchLimitOne
        var secret: CFTypeRef?
        switch SecItemCopyMatching(lookup as CFDictionary, &secret) {
        case errSecSuccess:
            guard let data = secret as? Data, let text = String(bytes: data, encoding: .utf8) else {
                throw .corruptedData
            }
            return text
        case errSecItemNotFound:
            throw .missingConfiguration
        default:
            throw .unavailable
        }
    }

    func save(_ secret: Data) throws(TunnelStorageError) {
        let oldItem = query
        let newItem = oldItem.merging([kSecValueData: secret]) { _, secret in secret }
        try SystemKeychainReplacement.replace(
            removingOldItem: { SecItemDelete(oldItem as CFDictionary) },
            addingNewItem: { SecItemAdd(newItem as CFDictionary, nil) }
        )
    }

    func delete() throws(TunnelStorageError) {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw .unavailable }
    }

    private var query: [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecUseDataProtectionKeychain: false,
        ]
    }
}
