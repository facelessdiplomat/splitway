public struct UninstallUseCase: Sendable {
    private let actions: [any UninstallAction]

    public init(actions: [any UninstallAction]) {
        self.actions = actions.sorted { first, second in first.step < second.step }
    }

    public func execute() async -> UninstallReport {
        var completed: [UninstallStep] = []
        var failed: [UninstallStep] = []
        for action in actions {
            do {
                try await action.perform()
                completed.append(action.step)
            } catch {
                failed.append(action.step)
            }
        }
        return UninstallReport(completedSteps: completed, failedSteps: failed)
    }
}
