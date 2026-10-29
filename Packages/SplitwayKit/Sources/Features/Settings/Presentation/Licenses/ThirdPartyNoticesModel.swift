import Observation
import Settings

@MainActor
@Observable
public final class ThirdPartyNoticesModel {
    public private(set) var state = ThirdPartyNoticesState.loading

    private let loadNotices: LoadThirdPartyNoticesUseCase

    public init(loadNotices: LoadThirdPartyNoticesUseCase) {
        self.loadNotices = loadNotices
    }

    public func load() async {
        do {
            state = .loaded(try await loadNotices.execute())
        } catch {
            state = .unavailable
        }
    }
}
