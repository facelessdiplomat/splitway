import Testing
import Updates
import UpdatesPresentation
import UpdatesTestSupport

@MainActor
@Suite
struct UpdatesModelTests {
    private static let idle = UpdaterState(checksAutomatically: false, canCheckForUpdates: true)

    @Test
    func offersNothingBeforeTheUpdaterAnswers() {
        let model = UpdatesModel(updater: FakeApplicationUpdater(state: Self.idle))

        #expect(!model.checksAutomatically)
        #expect(!model.canCheckForUpdates)
    }

    @Test
    func showsWhetherSplitwayChecksForUpdatesAutomatically() async {
        let state = UpdaterState(checksAutomatically: true, canCheckForUpdates: true)
        let model = UpdatesModel(updater: FakeApplicationUpdater(state: state))

        await model.load()

        #expect(model.checksAutomatically)
        #expect(model.canCheckForUpdates)
    }

    @Test
    func turnsAutomaticChecksOn() async {
        let updater = FakeApplicationUpdater(state: Self.idle)
        let model = UpdatesModel(updater: updater)
        await model.load()

        await model.setChecksAutomatically(true)

        #expect(model.checksAutomatically)
        #expect(await updater.state().checksAutomatically)
    }

    @Test
    func turnsAutomaticChecksOff() async {
        let updater = FakeApplicationUpdater(state: UpdaterState(checksAutomatically: true, canCheckForUpdates: true))
        let model = UpdatesModel(updater: updater)
        await model.load()

        await model.setChecksAutomatically(false)

        #expect(!model.checksAutomatically)
        #expect(await !updater.state().checksAutomatically)
    }

    @Test
    func checksForUpdatesWhenTheUpdaterIsReady() async {
        let updater = FakeApplicationUpdater(state: Self.idle)
        let model = UpdatesModel(updater: updater)
        await model.load()

        await model.checkForUpdates()

        #expect(updater.checkRequests == 1)
    }

    @Test
    func doesNotStartAnotherCheckWhileTheUpdaterIsBusy() async {
        let updater = FakeApplicationUpdater(state: UpdaterState(checksAutomatically: true, canCheckForUpdates: false))
        let model = UpdatesModel(updater: updater)
        await model.load()

        await model.checkForUpdates()

        #expect(updater.checkRequests == 0)
    }

    @Test
    func followsTheUpdaterWhileObservingIt() async {
        let busy = UpdaterState(checksAutomatically: true, canCheckForUpdates: false)
        let ready = UpdaterState(checksAutomatically: true, canCheckForUpdates: true)
        let model = UpdatesModel(updater: FakeApplicationUpdater(state: Self.idle, scriptedUpdates: [busy, ready]))

        await model.observe()

        #expect(model.checksAutomatically)
        #expect(model.canCheckForUpdates)
    }
}
