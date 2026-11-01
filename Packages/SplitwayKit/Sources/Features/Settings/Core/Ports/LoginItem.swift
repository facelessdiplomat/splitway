public protocol LoginItem: Sendable {
    func state() async -> LoginItemState
    func enable() async throws(LoginItemError)
    func disable() async throws(LoginItemError)
    func openSystemSettings() async
}
