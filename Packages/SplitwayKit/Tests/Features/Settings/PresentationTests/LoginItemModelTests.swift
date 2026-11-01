import Settings
import SettingsPresentation
import SettingsTestSupport
import Testing

@MainActor
@Suite
struct LoginItemModelTests {
    @Test
    func showsWhetherSplitwayOpensAtLogin() async {
        let model = LoginItemModel(loginItem: FakeLoginItem(state: .enabled))

        await model.load()

        #expect(model.isEnabled)
        #expect(!model.needsApproval)
    }

    @Test
    func opensAtLoginOnceTurnedOn() async {
        let loginItem = FakeLoginItem(state: .disabled)
        let model = LoginItemModel(loginItem: loginItem)
        await model.load()

        await model.setEnabled(true)

        #expect(model.isEnabled)
        #expect(await loginItem.state() == .enabled)
    }

    @Test
    func stopsOpeningAtLoginOnceTurnedOff() async {
        let loginItem = FakeLoginItem(state: .enabled)
        let model = LoginItemModel(loginItem: loginItem)
        await model.load()

        await model.setEnabled(false)

        #expect(!model.isEnabled)
        #expect(await loginItem.state() == .disabled)
    }

    @Test
    func explainsARefusedChangeAndKeepsTheRealState() async {
        let model = LoginItemModel(loginItem: FakeLoginItem(state: .disabled, refusesChanges: true))
        await model.load()

        await model.setEnabled(true)

        #expect(!model.isEnabled)
        #expect(model.failure == .systemRefused)
        model.dismissFailure()
        #expect(model.failure == nil)
    }

    @Test
    func asksForApprovalInSystemSettings() async {
        let loginItem = FakeLoginItem(state: .requiresApproval)
        let model = LoginItemModel(loginItem: loginItem)
        await model.load()

        await model.openSystemSettings()

        #expect(model.isEnabled)
        #expect(model.needsApproval)
        #expect(loginItem.systemSettingsOpenings == 1)
    }
}
