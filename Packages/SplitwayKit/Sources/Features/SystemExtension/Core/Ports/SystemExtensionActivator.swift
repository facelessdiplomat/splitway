public protocol SystemExtensionActivator: Sendable {
    func requestActivation() -> AsyncStream<SystemExtensionActivationEvent>
}
