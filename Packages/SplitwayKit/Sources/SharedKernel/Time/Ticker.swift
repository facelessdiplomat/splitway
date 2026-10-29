public protocol Ticker: Sendable {
    func ticks() -> AsyncStream<Void>
}
