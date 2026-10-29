import Synchronization
import SystemExtension

public final class ScriptedSystemExtensionActivator: SystemExtensionActivator {
    private let remainingRuns: Mutex<[[SystemExtensionActivationEvent]]>
    private let requests = Mutex(0)

    public init(runs: [[SystemExtensionActivationEvent]]) {
        remainingRuns = Mutex(runs)
    }

    public var requestCount: Int {
        requests.withLock { count in count }
    }

    public func requestActivation() -> AsyncStream<SystemExtensionActivationEvent> {
        requests.withLock { count in count += 1 }
        let events = remainingRuns.withLock { runs in runs.isEmpty ? [] : runs.removeFirst() }
        return AsyncStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }
}
