public protocol UninstallAction: Sendable {
    var step: UninstallStep { get }
    func perform() async throws(UninstallStepFailure)
}
