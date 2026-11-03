import Observation
import Settings

@MainActor
@Observable
public final class SettingsPresenter {
    let version: AppVersion
    let notices: ThirdPartyNoticesModel
    let loginItem: LoginItemModel?
    let uninstall: UninstallModel?

    public init(
        version: AppVersion,
        notices: ThirdPartyNoticesModel,
        loginItem: LoginItemModel? = nil,
        uninstall: UninstallModel? = nil
    ) {
        self.version = version
        self.notices = notices
        self.loginItem = loginItem
        self.uninstall = uninstall
    }
}
