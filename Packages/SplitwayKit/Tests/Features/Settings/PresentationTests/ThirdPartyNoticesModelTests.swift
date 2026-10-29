import Settings
import SettingsPresentation
import SettingsTestSupport
import Testing

@MainActor
@Suite
struct ThirdPartyNoticesModelTests {
    @Test
    func listsTheNoticesByNameOnceLoaded() async {
        let model = notices(
            InMemoryThirdPartyNoticeSource(notices: [.fixture(named: "ZIPFoundation"), .fixture(named: "Go")]))
        #expect(model.state == .loading)

        await model.load()

        #expect(model.state == .loaded([.fixture(named: "Go"), .fixture(named: "ZIPFoundation")]))
    }

    @Test
    func explainsUnavailableNotices() async {
        let model = notices(InMemoryThirdPartyNoticeSource(isAvailable: false))

        await model.load()

        #expect(model.state == .unavailable)
    }

    private func notices(_ source: InMemoryThirdPartyNoticeSource) -> ThirdPartyNoticesModel {
        ThirdPartyNoticesModel(loadNotices: LoadThirdPartyNoticesUseCase(source: source))
    }
}
