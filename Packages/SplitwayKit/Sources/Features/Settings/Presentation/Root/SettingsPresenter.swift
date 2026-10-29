import Observation
import Settings

@MainActor
@Observable
public final class SettingsPresenter {
    public var isShowing = false
    let version: AppVersion
    let notices: ThirdPartyNoticesModel

    public init(version: AppVersion, notices: ThirdPartyNoticesModel) {
        self.version = version
        self.notices = notices
    }

    public func show() {
        isShowing = true
    }
}
