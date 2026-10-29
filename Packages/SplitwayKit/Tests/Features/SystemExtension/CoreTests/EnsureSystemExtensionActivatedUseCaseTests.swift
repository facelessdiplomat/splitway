import SystemExtension
import Testing

@Suite
struct EnsureSystemExtensionActivatedUseCaseTests {
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
        let useCase = EnsureSystemExtensionActivatedUseCase(activator: ScriptedSystemExtensionActivator(events: events))

        var observed: [SystemExtensionState] = []
        for await state in useCase.execute() {
            observed.append(state)
        }

        #expect(observed == states)
    }
}

struct ScriptedSystemExtensionActivator: SystemExtensionActivator {
    let events: [SystemExtensionActivationEvent]

    func requestActivation() -> AsyncStream<SystemExtensionActivationEvent> {
        AsyncStream { continuation in
            for event in events {
                continuation.yield(event)
            }
            continuation.finish()
        }
    }
}
