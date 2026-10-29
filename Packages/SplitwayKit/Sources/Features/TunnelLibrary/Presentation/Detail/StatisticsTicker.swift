public protocol StatisticsTicker: Sendable {
    func ticks() -> AsyncStream<Void>
}
