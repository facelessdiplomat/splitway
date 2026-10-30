#if os(macOS)
    import Foundation
    import SecretDelivery

    public struct XPCExtensionSecretChannel: ExtensionSecretChannel {
        private let makeConnection: @Sendable () -> NSXPCConnection

        public init(makeConnection: @escaping @Sendable () -> NSXPCConnection) {
            self.makeConnection = makeConnection
        }

        public init(machServiceName: String) {
            self.init { NSXPCConnection(machServiceName: machServiceName, options: []) }
        }

        public func deliver(_ message: SecretDeliveryMessage) async throws(SecretDeliveryError) {
            let replyData = try await exchange(SecretDeliveryCodec.data(for: message)).get()
            let reply: SecretDeliveryReply
            do {
                reply = try SecretDeliveryCodec.reply(from: replyData)
            } catch {
                throw .extensionUnreachable
            }
            try reply.requireSuccess()
        }

        private func exchange(_ request: Data) async -> Result<Data, SecretDeliveryError> {
            let connection = makeConnection()
            connection.remoteObjectInterface = NSXPCInterface(with: (any SecretDeliveryXPCService).self)
            connection.resume()
            defer { connection.invalidate() }
            return await withCheckedContinuation { continuation in
                let outcome = OneShotContinuation(continuation)
                let proxy = connection.remoteObjectProxyWithErrorHandler { _ in
                    outcome.resume(returning: .failure(.extensionUnreachable))
                }
                guard let service = proxy as? any SecretDeliveryXPCService else {
                    outcome.resume(returning: .failure(.extensionUnreachable))
                    return
                }
                service.deliver(request) { replyData in
                    outcome.resume(returning: .success(replyData))
                }
            }
        }
    }
#endif
