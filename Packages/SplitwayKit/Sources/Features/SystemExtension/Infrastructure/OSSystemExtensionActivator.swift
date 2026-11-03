import Dispatch
import SystemExtension
import SystemExtensions

public struct OSSystemExtensionActivator: SystemExtensionActivator, SystemExtensionDeactivator {
    private let extensionIdentifier: String

    public init(extensionIdentifier: String) {
        self.extensionIdentifier = extensionIdentifier
    }

    public func requestActivation() -> AsyncStream<SystemExtensionActivationEvent> {
        submit(OSSystemExtensionRequest.activationRequest(forExtensionWithIdentifier:queue:))
    }

    public func requestDeactivation() -> AsyncStream<SystemExtensionActivationEvent> {
        submit(OSSystemExtensionRequest.deactivationRequest(forExtensionWithIdentifier:queue:))
    }

    private func submit(
        _ makeRequest: @escaping @Sendable (String, DispatchQueue) -> OSSystemExtensionRequest
    ) -> AsyncStream<SystemExtensionActivationEvent> {
        let extensionIdentifier = extensionIdentifier
        return AsyncStream { continuation in
            let delegate = ActivationRequestDelegate(continuation: continuation)
            let request = makeRequest(extensionIdentifier, .main)
            request.delegate = delegate
            continuation.onTermination = { _ in withExtendedLifetime(delegate) {} }
            OSSystemExtensionManager.shared.submitRequest(request)
        }
    }
}
