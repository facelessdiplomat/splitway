public struct UninstallReport: Sendable, Equatable {
    public let completedSteps: [UninstallStep]
    public let failedSteps: [UninstallStep]

    public init(completedSteps: [UninstallStep], failedSteps: [UninstallStep]) {
        self.completedSteps = completedSteps
        self.failedSteps = failedSteps
    }

    public var isComplete: Bool {
        failedSteps.isEmpty
    }
}
