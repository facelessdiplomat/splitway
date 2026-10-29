#if os(macOS)
    import Dispatch
    import SystemExtension
    import SystemExtensions

    public struct OSSystemExtensionActivator: SystemExtensionActivator {
        private let extensionIdentifier: String

        public init(extensionIdentifier: String) {
            self.extensionIdentifier = extensionIdentifier
        }

        public func requestActivation() -> AsyncStream<SystemExtensionActivationEvent> {
            let extensionIdentifier = extensionIdentifier
            return AsyncStream { continuation in
                let delegate = ActivationRequestDelegate(continuation: continuation)
                let request = OSSystemExtensionRequest.activationRequest(
                    forExtensionWithIdentifier: extensionIdentifier,
                    queue: .main
                )
                request.delegate = delegate
                continuation.onTermination = { _ in withExtendedLifetime(delegate) {} }
                OSSystemExtensionManager.shared.submitRequest(request)
            }
        }
    }
#endif
