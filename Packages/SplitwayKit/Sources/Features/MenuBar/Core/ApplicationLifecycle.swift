public protocol ApplicationLifecycle: Sendable {
    @MainActor
    func activate()

    @MainActor
    func terminate()
}
