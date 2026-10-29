import Settings

public struct SettingsAssembly: Sendable {
    public init() {}

    public var loadThirdPartyNotices: LoadThirdPartyNoticesUseCase {
        LoadThirdPartyNoticesUseCase(source: BundledThirdPartyNoticeSource())
    }
}
