public protocol SystemExtensionDeactivator: Sendable {
    func requestDeactivation() -> AsyncStream<SystemExtensionActivationEvent>
}
