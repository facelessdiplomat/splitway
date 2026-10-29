public struct ClearLogUseCase: Sendable {
    private let history: any LogHistory

    public init(history: any LogHistory) {
        self.history = history
    }

    public func execute() async throws(LogStoreError) {
        try await history.removeAll()
    }
}
