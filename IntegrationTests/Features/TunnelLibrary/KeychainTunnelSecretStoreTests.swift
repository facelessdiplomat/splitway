import Foundation
import Security
import Testing
import TunnelLibrary
import TunnelLibraryInfrastructure

@Suite
final class KeychainTunnelSecretStoreTests {
    private let service: String
    private let store: KeychainTunnelSecretStore

    init() {
        let service = "splitway-integration-tests-\(UUID().uuidString)"
        self.service = service
        store = KeychainTunnelSecretStore(service: service)
    }

    deinit {
        let serviceItems: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecUseDataProtectionKeychain: true,
        ]
        SecItemDelete(serviceItems as CFDictionary)
    }

    @Test
    func readsBackASavedConfiguration() async throws {
        let tunnel = TunnelIdentifier()

        try await store.saveConfigurationText("first configuration", for: tunnel)

        #expect(try await store.loadConfigurationText(for: tunnel) == "first configuration")
    }

    @Test
    func overwritesAnExistingConfiguration() async throws {
        let tunnel = TunnelIdentifier()
        try await store.saveConfigurationText("first configuration", for: tunnel)

        try await store.saveConfigurationText("second configuration", for: tunnel)

        #expect(try await store.loadConfigurationText(for: tunnel) == "second configuration")
    }

    @Test
    func keepsConfigurationsOfDifferentTunnelsApart() async throws {
        let office = TunnelIdentifier()
        let prague = TunnelIdentifier()

        try await store.saveConfigurationText("office configuration", for: office)
        try await store.saveConfigurationText("prague configuration", for: prague)

        #expect(try await store.loadConfigurationText(for: office) == "office configuration")
        #expect(try await store.loadConfigurationText(for: prague) == "prague configuration")
    }

    @Test
    func reportsAMissingConfiguration() async {
        let store = store

        await #expect(throws: TunnelStorageError.missingConfiguration) {
            try await store.loadConfigurationText(for: TunnelIdentifier())
        }
    }

    @Test
    func forgetsADeletedConfiguration() async throws {
        let store = store
        let tunnel = TunnelIdentifier()
        try await store.saveConfigurationText("configuration", for: tunnel)

        try await store.deleteConfigurationText(for: tunnel)

        await #expect(throws: TunnelStorageError.missingConfiguration) {
            try await store.loadConfigurationText(for: tunnel)
        }
    }

    @Test
    func toleratesDeletingAMissingConfiguration() async throws {
        try await store.deleteConfigurationText(for: TunnelIdentifier())
    }

    @Test
    func keepsSecretsOnThisDeviceReadableAfterFirstUnlock() async throws {
        let tunnel = TunnelIdentifier()
        try await store.saveConfigurationText("first configuration", for: tunnel)
        try await store.saveConfigurationText("second configuration", for: tunnel)

        let attributes = try storedAttributes(of: tunnel)

        let accessibility = attributes[kSecAttrAccessible as String] as? String
        #expect(accessibility == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
        #expect(attributes[kSecAttrSynchronizable as String] as? Bool != true)
    }

    private func storedAttributes(of tunnel: TunnelIdentifier) throws -> [String: Any] {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: tunnel.rawValue.uuidString,
            kSecUseDataProtectionKeychain: true,
            kSecReturnAttributes: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var attributes: CFTypeRef?
        try #require(SecItemCopyMatching(query as CFDictionary, &attributes) == errSecSuccess)
        return try #require(attributes as? [String: Any])
    }
}
