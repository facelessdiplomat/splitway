public struct EnsureSystemExtensionActivatedUseCase: Sendable {
    private let activator: any SystemExtensionActivator

    public init(activator: any SystemExtensionActivator) {
        self.activator = activator
    }

    public func execute() -> AsyncStream<SystemExtensionState> {
        let events = activator.requestActivation()
        return AsyncStream { continuation in
            let relay = Task {
                continuation.yield(.activating)
                for await event in events {
                    continuation.yield(SystemExtensionState(after: event))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in relay.cancel() }
        }
    }
}
