import Foundation
import Security
import TunnelLibrary

public struct KeychainTunnelSecretStore: ErasableTunnelSecretStore {
    public static let defaultService = "Splitway tunnel configuration"
    private static let maximumDeletions = 10_000

    private let service: String
    private let accessGroup: String?

    public init(service: String = Self.defaultService, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    public func loadConfigurationText(for tunnel: TunnelIdentifier) async throws(TunnelStorageError) -> String {
        var query = itemQuery(for: tunnel)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        var secret: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &secret) {
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

    public func saveConfigurationText(_ text: String, for tunnel: TunnelIdentifier) async throws(TunnelStorageError) {
        let query = itemQuery(for: tunnel)
        let secretAttributes: [CFString: Any] = [
            kSecValueData: Data(text.utf8),
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        switch SecItemAdd(query.merging(secretAttributes) { _, secret in secret } as CFDictionary, nil) {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            guard SecItemUpdate(query as CFDictionary, secretAttributes as CFDictionary) == errSecSuccess else {
                throw .unavailable
            }
        default:
            throw .unavailable
        }
    }

    public func deleteConfigurationText(for tunnel: TunnelIdentifier) async throws(TunnelStorageError) {
        let status = SecItemDelete(itemQuery(for: tunnel) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw .unavailable }
    }

    public func deleteAllConfigurationTexts() async throws(TunnelStorageError) {
        let query = serviceQuery
        for _ in 0..<Self.maximumDeletions {
            switch SecItemDelete(query as CFDictionary) {
            case errSecSuccess: continue
            case errSecItemNotFound: return
            default: throw .unavailable
            }
        }
        throw .unavailable
    }

    private func itemQuery(for tunnel: TunnelIdentifier) -> [CFString: Any] {
        var query = serviceQuery
        query[kSecAttrAccount] = tunnel.rawValue.uuidString
        return query
    }

    private var serviceQuery: [CFString: Any] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrSynchronizable: false,
            kSecUseDataProtectionKeychain: true,
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup] = accessGroup
        }
        return query
    }
}
