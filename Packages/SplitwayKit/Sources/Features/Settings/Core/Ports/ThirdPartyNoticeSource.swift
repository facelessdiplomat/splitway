public protocol ThirdPartyNoticeSource: Sendable {
    func notices() async throws(ThirdPartyNoticeError) -> [ThirdPartyNotice]
}
