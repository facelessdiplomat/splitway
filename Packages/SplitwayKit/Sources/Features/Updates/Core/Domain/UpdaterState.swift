public struct UpdaterState: Sendable, Equatable {
    public let checksAutomatically: Bool
    public let canCheckForUpdates: Bool

    public init(checksAutomatically: Bool, canCheckForUpdates: Bool) {
        self.checksAutomatically = checksAutomatically
        self.canCheckForUpdates = canCheckForUpdates
    }
}
