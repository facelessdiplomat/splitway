import SecretDelivery
import TunnelLibrary

public actor LoopbackExtensionSecretChannel: ExtensionSecretChannel {
    public private(set) var deliveredMessageCount = 0
    private let handler: SecretDeliveryRequestHandler
    private var isReachable: Bool

    public init(extensionStore: any ErasableTunnelSecretStore, isReachable: Bool = true) {
        handler = SecretDeliveryRequestHandler(store: extensionStore)
        self.isReachable = isReachable
    }

    public func makeUnreachable() {
        isReachable = false
    }

    public func deliver(_ message: SecretDeliveryMessage) async throws(SecretDeliveryError) {
        guard isReachable else { throw .extensionUnreachable }
        deliveredMessageCount += 1
        let replyData = await handler.reply(to: SecretDeliveryCodec.data(for: message))
        let reply: SecretDeliveryReply
        do {
            reply = try SecretDeliveryCodec.reply(from: replyData)
        } catch {
            throw .extensionUnreachable
        }
        try reply.requireSuccess()
    }
}
