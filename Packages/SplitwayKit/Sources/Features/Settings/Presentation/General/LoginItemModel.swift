import Observation
import Settings

@MainActor
@Observable
public final class LoginItemModel {
    public private(set) var state: LoginItemState?
    public private(set) var failure: LoginItemError?

    private let loginItem: any LoginItem

    public init(loginItem: any LoginItem) {
        self.loginItem = loginItem
    }

    public var isEnabled: Bool {
        state == .enabled || state == .requiresApproval
    }

    public var needsApproval: Bool {
        state == .requiresApproval
    }

    public func load() async {
        state = await loginItem.state()
    }

    public func setEnabled(_ isEnabled: Bool) async {
        do {
            if isEnabled {
                try await loginItem.enable()
            } else {
                try await loginItem.disable()
            }
        } catch {
            failure = error
        }
        await load()
    }

    public func openSystemSettings() async {
        await loginItem.openSystemSettings()
    }

    public func dismissFailure() {
        failure = nil
    }
}
