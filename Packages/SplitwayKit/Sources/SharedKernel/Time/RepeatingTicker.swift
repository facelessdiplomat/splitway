public struct RepeatingTicker: Ticker {
    private let interval: Duration

    public init(interval: Duration) {
        self.interval = interval
    }

    public func ticks() -> AsyncStream<Void> {
        let interval = interval
        return AsyncStream { continuation in
            let timer = Task {
                while !Task.isCancelled {
                    continuation.yield()
                    try? await Task.sleep(for: interval)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in timer.cancel() }
        }
    }
}
