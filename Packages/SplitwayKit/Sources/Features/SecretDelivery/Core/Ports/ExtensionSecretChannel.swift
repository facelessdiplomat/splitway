public protocol ExtensionSecretChannel: Sendable {
    func deliver(_ message: SecretDeliveryMessage) async throws(SecretDeliveryError)
}
