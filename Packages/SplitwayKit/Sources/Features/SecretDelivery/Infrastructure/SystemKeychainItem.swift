#if os(macOS)
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
            let attributes: [CFString: Any] = [kSecValueData: secret]
            let newItem = query.merging(attributes) { _, secret in secret }
            let status = SecItemAdd(newItem as CFDictionary, nil)
            if status == errSecSuccess { return }
            guard status == errSecDuplicateItem else { throw .unavailable }
            if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecSuccess { return }
            SecItemDelete(query as CFDictionary)
            guard SecItemAdd(newItem as CFDictionary, nil) == errSecSuccess else { throw .unavailable }
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
#endif
