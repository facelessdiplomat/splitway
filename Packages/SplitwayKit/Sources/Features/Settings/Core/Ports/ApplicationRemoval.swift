public protocol ApplicationRemoval: Sendable {
    func moveToTrashAndQuit() async throws(ApplicationRemovalError)
    func quit() async
}
