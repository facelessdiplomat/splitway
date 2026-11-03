import Observation
import Updates

@MainActor
@Observable
public final class UpdatesModel {
    public private(set) var state: UpdaterState?

    private let updater: any ApplicationUpdater

    public init(updater: any ApplicationUpdater) {
        self.updater = updater
    }

    public var checksAutomatically: Bool {
        state?.checksAutomatically ?? false
    }

    public var canCheckForUpdates: Bool {
        state?.canCheckForUpdates ?? false
    }

    public func load() async {
        state = await updater.state()
    }

    public func observe() async {
        for await state in await updater.stateUpdates() {
            self.state = state
        }
    }

    public func setChecksAutomatically(_ checksAutomatically: Bool) async {
        await updater.setChecksAutomatically(checksAutomatically)
        await load()
    }

    public func checkForUpdates() async {
        guard canCheckForUpdates else { return }
        await updater.checkForUpdates()
    }
}
