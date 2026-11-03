import Foundation
import SecretDelivery

final class SecretDeliveryRequestReceiver: NSObject, SecretDeliveryXPCService {
    private let handler: SecretDeliveryRequestHandler

    init(handler: SecretDeliveryRequestHandler) {
        self.handler = handler
    }

    func deliver(_ request: Data, withReply reply: @escaping @Sendable (Data) -> Void) {
        let handler = handler
        Task {
            reply(await handler.reply(to: request))
        }
    }
}
