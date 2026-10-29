public struct ExportLogUseCase: Sendable {
    private let history: any LogHistory

    public init(history: any LogHistory) {
        self.history = history
    }

    public func execute() async throws(LogStoreError) -> String {
        LogTextFormatter.text(of: try await history.entries())
    }
}
