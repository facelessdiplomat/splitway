#if os(macOS)
    import Foundation
    import SecretDelivery
    import TunnelLibrary

    public final class SecretDeliveryListener: NSObject, NSXPCListenerDelegate {
        private let listener: NSXPCListener
        private let handler: SecretDeliveryRequestHandler

        public init(listener: NSXPCListener, store: any TunnelSecretStore, clientRequirement: ClientCodeRequirement?) {
            self.listener = listener
            handler = SecretDeliveryRequestHandler(store: store)
            super.init()
            listener.delegate = self
            if let clientRequirement {
                listener.setConnectionCodeSigningRequirement(clientRequirement.text)
            }
        }

        public convenience init(
            machServiceName: String,
            store: any TunnelSecretStore,
            clientRequirement: ClientCodeRequirement
        ) {
            self.init(
                listener: NSXPCListener(machServiceName: machServiceName),
                store: store,
                clientRequirement: clientRequirement
            )
        }

        public static func anonymous(
            store: any TunnelSecretStore,
            clientRequirement: ClientCodeRequirement? = nil
        ) -> SecretDeliveryListener {
            SecretDeliveryListener(listener: .anonymous(), store: store, clientRequirement: clientRequirement)
        }

        public var endpoint: NSXPCListenerEndpoint {
            listener.endpoint
        }

        public func start() {
            listener.resume()
        }

        public func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
            connection.exportedInterface = NSXPCInterface(with: (any SecretDeliveryXPCService).self)
            connection.exportedObject = SecretDeliveryRequestReceiver(handler: handler)
            connection.resume()
            return true
        }
    }
#endif
