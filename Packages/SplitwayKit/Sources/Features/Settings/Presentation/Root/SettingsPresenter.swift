import Observation
import Settings
import UpdatesPresentation

@MainActor
@Observable
public final class SettingsPresenter {
    public var isShowing = false
    let version: AppVersion
    let notices: ThirdPartyNoticesModel
    let loginItem: LoginItemModel?
    let updates: UpdatesModel?
    let uninstall: UninstallModel?

    public init(
        version: AppVersion,
        notices: ThirdPartyNoticesModel,
        loginItem: LoginItemModel? = nil,
        updates: UpdatesModel? = nil,
        uninstall: UninstallModel? = nil
    ) {
        self.version = version
        self.notices = notices
        self.loginItem = loginItem
        self.updates = updates
        self.uninstall = uninstall
    }

    public func show() {
        isShowing = true
    }
}
