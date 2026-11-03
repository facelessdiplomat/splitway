public protocol ApplicationUpdater: Sendable {
    func state() async -> UpdaterState
    func stateUpdates() async -> AsyncStream<UpdaterState>
    func setChecksAutomatically(_ checksAutomatically: Bool) async
    func checkForUpdates() async
}
