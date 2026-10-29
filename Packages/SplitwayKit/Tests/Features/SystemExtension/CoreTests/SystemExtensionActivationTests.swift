import SystemExtension
import SystemExtensionTestSupport
import Testing

@Suite
struct SystemExtensionActivationTests {
    @Test(arguments: [
        (
            [SystemExtensionActivationEvent.needsUserApproval, .completed],
            [SystemExtensionState.activating, .awaitingUserApproval, .activated]
        ),
        ([.completed], [.activating, .activated]),
        ([.willCompleteAfterReboot], [.activating, .requiresReboot]),
        (
            [.needsUserApproval, .failed(.appNotInApplicationsFolder)],
            [.activating, .awaitingUserApproval, .failed(.appNotInApplicationsFolder)]
        ),
    ])
    func followsTheActivationRequestToItsOutcome(
        events: [SystemExtensionActivationEvent],
        states: [SystemExtensionState]
    ) async {
        let useCase = EnsureSystemExtensionActivatedUseCase(activator: ScriptedSystemExtensionActivator(runs: [events]))

        var observed: [SystemExtensionState] = []
        for await state in useCase.execute() {
            observed.append(state)
        }

        #expect(observed == states)
    }
}
