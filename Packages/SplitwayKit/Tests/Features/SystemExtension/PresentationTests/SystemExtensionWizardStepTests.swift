import SystemExtension
import SystemExtensionPresentation
import Testing

@Suite
struct SystemExtensionWizardStepTests {
    struct StateStep: Sendable {
        let state: SystemExtensionState
        let step: SystemExtensionWizardStep
    }

    @Test(arguments: [
        StateStep(state: .activating, step: .installing),
        StateStep(state: .awaitingUserApproval, step: .awaitingApproval),
        StateStep(state: .activated, step: .ready),
        StateStep(state: .requiresReboot, step: .restartRequired),
        StateStep(state: .failed(.appNotInApplicationsFolder), step: .failed(.appNotInApplicationsFolder)),
    ])
    func showsAStepForEveryActivationState(pair: StateStep) {
        #expect(SystemExtensionWizardStep(state: pair.state) == pair.step)
    }

    @Test(arguments: [
        (SystemExtensionWizardStep.introduction, false),
        (.installing, false),
        (.awaitingApproval, true),
        (.ready, false),
        (.restartRequired, true),
        (.failed(.cancelled), true),
    ])
    func asksForAttentionOnlyWhenTheUserMustAct(step: SystemExtensionWizardStep, needsAttention: Bool) {
        #expect(step.needsAttention == needsAttention)
    }
}
