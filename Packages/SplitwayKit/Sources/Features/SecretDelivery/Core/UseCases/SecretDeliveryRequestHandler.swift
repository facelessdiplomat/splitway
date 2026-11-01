import Foundation
import TunnelLibrary

public struct SecretDeliveryRequestHandler: Sendable {
    private let store: any ErasableTunnelSecretStore

    public init(store: any ErasableTunnelSecretStore) {
        self.store = store
    }

    public func reply(to request: Data) async -> Data {
        SecretDeliveryCodec.data(for: await outcome(of: request))
    }

    private func outcome(of request: Data) async -> SecretDeliveryReply {
        let message: SecretDeliveryMessage
        do {
            message = try SecretDeliveryCodec.message(from: request)
        } catch {
            return .failed(error == .unsupportedSchemaVersion ? .unsupportedSchemaVersion : .malformedMessage)
        }
        do {
            switch message {
            case .store(let tunnel, let configurationText):
                try await store.saveConfigurationText(configurationText, for: tunnel)
            case .remove(let tunnel):
                try await store.deleteConfigurationText(for: tunnel)
            case .removeAll:
                try await store.deleteAllConfigurationTexts()
            }
            return .done
        } catch {
            return .failed(.storageUnavailable)
        }
    }
}
