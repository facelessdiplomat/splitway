import SystemExtension

public struct ScriptedSystemExtensionDeactivator: SystemExtensionDeactivator {
    private let events: [SystemExtensionActivationEvent]

    public init(events: [SystemExtensionActivationEvent]) {
        self.events = events
    }

    public func requestDeactivation() -> AsyncStream<SystemExtensionActivationEvent> {
        AsyncStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }
}
