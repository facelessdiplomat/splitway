import Settings
import SettingsTestSupport
import Testing

@Suite
struct UninstallUseCaseTests {
    @Test
    func performsTheStepsInTheirOrder() async {
        let recorder = UninstallStepRecorder()
        let actions = UninstallStep.allCases.reversed().map { step in
            RecordingUninstallAction(step, recorder: recorder)
        }

        let report = await UninstallUseCase(actions: actions).execute()

        #expect(recorder.steps == UninstallStep.allCases)
        #expect(report.completedSteps == UninstallStep.allCases)
        #expect(report.isComplete)
    }

    @Test
    func continuesAfterAFailedStepAndReportsIt() async {
        let recorder = UninstallStepRecorder()
        let actions = UninstallStep.allCases.map { step in
            RecordingUninstallAction(step, recorder: recorder, fails: step == .removeSecrets)
        }

        let report = await UninstallUseCase(actions: actions).execute()

        #expect(recorder.steps == UninstallStep.allCases)
        #expect(report.failedSteps == [.removeSecrets])
        #expect(report.completedSteps == UninstallStep.allCases.filter { step in step != .removeSecrets })
        #expect(!report.isComplete)
    }

    @Test
    func skipsStepsThatThePlatformDoesNotHave() async {
        let recorder = UninstallStepRecorder()
        let actions = [RecordingUninstallAction(.removeAppData, recorder: recorder)]

        let report = await UninstallUseCase(actions: actions).execute()

        #expect(recorder.steps == [.removeAppData])
        #expect(report.isComplete)
    }
}
