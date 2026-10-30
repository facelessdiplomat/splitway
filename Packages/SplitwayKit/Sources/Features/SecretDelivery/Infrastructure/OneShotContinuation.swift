#if os(macOS)
    import Synchronization

    final class OneShotContinuation<Value: Sendable>: Sendable {
        private let continuation: Mutex<CheckedContinuation<Value, Never>?>

        init(_ continuation: CheckedContinuation<Value, Never>) {
            self.continuation = Mutex(continuation)
        }

        func resume(returning value: Value) {
            let pending = continuation.withLock { stored -> CheckedContinuation<Value, Never>? in
                let taken = stored
                stored = nil
                return taken
            }
            pending?.resume(returning: value)
        }
    }
#endif
