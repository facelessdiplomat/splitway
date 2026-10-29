import Foundation

public struct LoadThirdPartyNoticesUseCase: Sendable {
    private let source: any ThirdPartyNoticeSource

    public init(source: any ThirdPartyNoticeSource) {
        self.source = source
    }

    public func execute() async throws(ThirdPartyNoticeError) -> [ThirdPartyNotice] {
        try await source.notices().sorted { first, second in
            first.name.localizedStandardCompare(second.name) == .orderedAscending
        }
    }
}
