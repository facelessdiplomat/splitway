import Settings
import SettingsPresentation
import SettingsTestSupport
import Testing

@MainActor
@Suite
struct UninstallModelTests {
    private let recorder = UninstallStepRecorder()

    @Test
    func asksBeforeUninstallingAndDoesNothingWhenCancelled() {
        let model = makeModel()

        model.requestUninstall()
        #expect(model.phase == .confirming)
        model.cancel()

        #expect(model.phase == .idle)
        #expect(recorder.steps.isEmpty)
    }

    @Test
    func uninstallsAfterConfirmationAndReports() async {
        let model = makeModel()
        model.requestUninstall()

        await model.confirm()

        #expect(recorder.steps == UninstallStep.allCases)
        #expect(model.phase == .finished(UninstallReport(completedSteps: UninstallStep.allCases, failedSteps: [])))
    }

    @Test
    func reportsTheStepsThatFailed() async {
        let model = makeModel(failing: .deactivateSystemExtension)
        model.requestUninstall()

        await model.confirm()

        guard case .finished(let report) = model.phase else {
            Issue.record("The uninstall did not finish")
            return
        }
        #expect(report.failedSteps == [.deactivateSystemExtension])
    }

    @Test
    func showsTheApplicationInFinderOrQuits() async {
        let application = FakeApplicationRemoval()
        let model = makeModel(application: application)

        await model.showInFinder()
        await model.quit()

        #expect(application.performedRequests == ["show in Finder", "quit"])
    }

    private func makeModel(
        failing failingStep: UninstallStep? = nil,
        application: FakeApplicationRemoval = FakeApplicationRemoval()
    ) -> UninstallModel {
        let actions = UninstallStep.allCases.map { step in
            RecordingUninstallAction(step, recorder: recorder, fails: step == failingStep)
        }
        return UninstallModel(uninstall: UninstallUseCase(actions: actions), application: application)
    }
}
