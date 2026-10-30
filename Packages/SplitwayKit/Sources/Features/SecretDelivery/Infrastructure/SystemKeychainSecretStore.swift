#if os(macOS)
    import Foundation
    import Security
    import TunnelLibrary

    public struct SystemKeychainSecretStore: TunnelSecretStore {
        public static let defaultService = "Splitway tunnel configuration"
        private static let queue = DispatchQueue(label: "Splitway.SystemKeychainSecretStore", qos: .userInitiated)

        private let service: String

        public init(service: String = Self.defaultService) {
            self.service = service
        }

        public func loadConfigurationText(for tunnel: TunnelIdentifier) async throws(TunnelStorageError) -> String {
            let item = SystemKeychainItem(service: service, account: tunnel.rawValue.uuidString)
            return try await Self.perform { () throws(TunnelStorageError) -> String in try item.loadText() }
        }

        public func saveConfigurationText(
            _ text: String,
            for tunnel: TunnelIdentifier
        ) async throws(TunnelStorageError) {
            let item = SystemKeychainItem(service: service, account: tunnel.rawValue.uuidString)
            let secret = Data(text.utf8)
            try await Self.perform { () throws(TunnelStorageError) in try item.save(secret) }
        }

        public func deleteConfigurationText(for tunnel: TunnelIdentifier) async throws(TunnelStorageError) {
            let item = SystemKeychainItem(service: service, account: tunnel.rawValue.uuidString)
            try await Self.perform { () throws(TunnelStorageError) in try item.delete() }
        }

        private static func perform<Value: Sendable>(
            _ operation: @escaping @Sendable () throws(TunnelStorageError) -> Value
        ) async throws(TunnelStorageError) -> Value {
            let outcome = await withCheckedContinuation { continuation in
                queue.async {
                    continuation.resume(returning: Result { () throws(TunnelStorageError) -> Value in try operation() })
                }
            }
            return try outcome.get()
        }
    }
#endif
