public struct LoginItemUninstallAction: UninstallAction {
    public let step = UninstallStep.removeLoginItem
    private let loginItem: any LoginItem

    public init(loginItem: any LoginItem) {
        self.loginItem = loginItem
    }

    public func perform() async throws(UninstallStepFailure) {
        guard await loginItem.state() != .disabled else { return }
        do {
            try await loginItem.disable()
        } catch {
            throw UninstallStepFailure()
        }
    }
}
