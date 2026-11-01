import Settings
import Synchronization

public final class FakeLoginItem: LoginItem {
    private let current: Mutex<LoginItemState>
    private let refusesChanges: Bool
    private let openedSettings = Mutex(0)

    public init(state: LoginItemState = .disabled, refusesChanges: Bool = false) {
        current = Mutex(state)
        self.refusesChanges = refusesChanges
    }

    public var systemSettingsOpenings: Int {
        openedSettings.withLock { count in count }
    }

    public func state() async -> LoginItemState {
        current.withLock { state in state }
    }

    public func enable() async throws(LoginItemError) {
        guard !refusesChanges else { throw .systemRefused }
        current.withLock { state in state = .enabled }
    }

    public func disable() async throws(LoginItemError) {
        guard !refusesChanges else { throw .systemRefused }
        current.withLock { state in state = .disabled }
    }

    public func openSystemSettings() async {
        openedSettings.withLock { count in count += 1 }
    }
}
