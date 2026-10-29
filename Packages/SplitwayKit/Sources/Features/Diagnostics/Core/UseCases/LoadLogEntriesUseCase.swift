public struct LoadLogEntriesUseCase: Sendable {
    private let history: any LogHistory

    public init(history: any LogHistory) {
        self.history = history
    }

    public func execute() async throws(LogStoreError) -> [LogEntry] {
        Array(try await history.entries().reversed())
    }
}
