public protocol ApplicationRemoval: Sendable {
    func showInFinderAndQuit() async
    func quit() async
}
