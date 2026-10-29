import Settings
import SettingsTestSupport
import Testing

@Suite
struct LoadThirdPartyNoticesUseCaseTests {
    @Test
    func listsNoticesByNameWhateverTheirCase() async throws {
        let source = InMemoryThirdPartyNoticeSource(notices: [
            .fixture(named: "ZIPFoundation"), .fixture(named: "go"), .fixture(named: "WireGuardKit"),
        ])

        let notices = try await LoadThirdPartyNoticesUseCase(source: source).execute()

        #expect(notices.map(\.name) == ["go", "WireGuardKit", "ZIPFoundation"])
    }

    @Test
    func reportsUnavailableNotices() async {
        let source = InMemoryThirdPartyNoticeSource(isAvailable: false)

        await #expect(throws: ThirdPartyNoticeError.unavailable) {
            try await LoadThirdPartyNoticesUseCase(source: source).execute()
        }
    }
}
