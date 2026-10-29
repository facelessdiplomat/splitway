import Settings

public struct InMemoryThirdPartyNoticeSource: ThirdPartyNoticeSource {
    private let storedNotices: [ThirdPartyNotice]
    private let isAvailable: Bool

    public init(notices: [ThirdPartyNotice] = [], isAvailable: Bool = true) {
        storedNotices = notices
        self.isAvailable = isAvailable
    }

    public func notices() async throws(ThirdPartyNoticeError) -> [ThirdPartyNotice] {
        guard isAvailable else { throw .unavailable }
        return storedNotices
    }
}
