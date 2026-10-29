import Settings

public enum ThirdPartyNoticesState: Sendable, Equatable {
    case loading
    case loaded([ThirdPartyNotice])
    case unavailable
}
