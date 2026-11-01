import Settings
import SettingsTestSupport
import Testing

@Suite
struct LoginItemUninstallActionTests {
    @Test(arguments: [LoginItemState.enabled, .requiresApproval])
    func stopsOpeningAtLogin(state: LoginItemState) async throws {
        let loginItem = FakeLoginItem(state: state)

        try await LoginItemUninstallAction(loginItem: loginItem).perform()

        #expect(await loginItem.state() == .disabled)
    }

    @Test
    func leavesATurnedOffLoginItemAlone() async throws {
        let loginItem = FakeLoginItem(state: .disabled, refusesChanges: true)

        try await LoginItemUninstallAction(loginItem: loginItem).perform()

        #expect(await loginItem.state() == .disabled)
    }

    @Test
    func failsWhenTheSystemRefuses() async {
        let action = LoginItemUninstallAction(loginItem: FakeLoginItem(state: .enabled, refusesChanges: true))

        await #expect(throws: UninstallStepFailure()) {
            try await action.perform()
        }
    }
}
