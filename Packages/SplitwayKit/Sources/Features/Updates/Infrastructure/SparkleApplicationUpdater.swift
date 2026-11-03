import Combine
import Sparkle
import Updates

@MainActor
public final class SparkleApplicationUpdater: ApplicationUpdater {
    private let controller: SPUStandardUpdaterController
    private var subscriptions: [AnyCancellable] = []

    public init() {
        controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    public func state() async -> UpdaterState {
        currentState
    }

    public func stateUpdates() async -> AsyncStream<UpdaterState> {
        let updater = controller.updater
        let (updates, continuation) = AsyncStream.makeStream(of: UpdaterState.self)
        let subscription = updater.publisher(for: \.automaticallyChecksForUpdates)
            .combineLatest(updater.publisher(for: \.canCheckForUpdates))
            .sink { checksAutomatically, canCheckForUpdates in
                continuation.yield(
                    UpdaterState(checksAutomatically: checksAutomatically, canCheckForUpdates: canCheckForUpdates)
                )
            }
        subscriptions.append(subscription)
        return updates
    }

    public func setChecksAutomatically(_ checksAutomatically: Bool) async {
        controller.updater.automaticallyChecksForUpdates = checksAutomatically
    }

    public func checkForUpdates() async {
        controller.checkForUpdates(nil)
    }

    private var currentState: UpdaterState {
        UpdaterState(
            checksAutomatically: controller.updater.automaticallyChecksForUpdates,
            canCheckForUpdates: controller.updater.canCheckForUpdates
        )
    }
}
