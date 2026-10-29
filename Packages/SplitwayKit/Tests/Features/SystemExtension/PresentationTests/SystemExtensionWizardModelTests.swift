import SystemExtension
import SystemExtensionPresentation
import SystemExtensionTestSupport
import Testing

@MainActor
@Suite
struct SystemExtensionWizardModelTests {
    @Test
    func introducesTheExtensionBeforeInstalling() {
        let model = wizard(ScriptedSystemExtensionActivator(runs: []))

        #expect(model.step == .introduction)
        #expect(!model.needsAttention)
    }

    @Test
    func movesOnByItselfOnceTheUserApproves() async {
        let activator = ControlledSystemExtensionActivator()
        let model = wizard(activator)
        let installation = Task { await model.install() }
        await activator.waitUntilRequested()

        activator.send(.needsUserApproval)
        activator.send(.completed)
        activator.finish()
        await installation.value

        #expect(model.step == .ready)
    }

    @Test
    func requestsActivationOnceWhileItIsInProgress() async {
        let activator = ControlledSystemExtensionActivator()
        let model = wizard(activator)
        let installation = Task { await model.install() }
        await activator.waitUntilRequested()

        await model.install()
        activator.send(.completed)
        activator.finish()
        await installation.value

        #expect(activator.requestCount == 1)
        #expect(model.step == .ready)
    }

    @Test
    func startsAgainAfterAFailure() async {
        let activator = ScriptedSystemExtensionActivator(runs: [
            [.failed(.cancelled)], [.needsUserApproval, .completed],
        ])
        let model = wizard(activator)

        await model.install()
        #expect(model.step == .failed(.cancelled))
        #expect(model.needsAttention)
        await model.install()

        #expect(model.step == .ready)
        #expect(activator.requestCount == 2)
    }

    @Test
    func staysOutOfTheWayOncePostponed() async {
        let model = wizard(ScriptedSystemExtensionActivator(runs: [[.needsUserApproval]]))
        await model.install()
        #expect(model.needsAttention)

        model.postpone()

        #expect(!model.needsAttention)
        #expect(model.step == .awaitingApproval)
    }

    private func wizard(_ activator: any SystemExtensionActivator) -> SystemExtensionWizardModel {
        SystemExtensionWizardModel(activate: EnsureSystemExtensionActivatedUseCase(activator: activator))
    }
}
