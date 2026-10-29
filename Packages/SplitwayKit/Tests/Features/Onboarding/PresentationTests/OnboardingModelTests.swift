import Onboarding
import OnboardingPresentation
import OnboardingTestSupport
import SystemExtension
import SystemExtensionPresentation
import SystemExtensionTestSupport
import Testing

@MainActor
@Suite
struct OnboardingModelTests {
    @Test
    func showsOnboardingUntilItIsCompleted() {
        let record = InMemoryOnboardingRecord()
        let model = OnboardingModel(record: record)
        #expect(model.isPresented)

        model.finish()

        #expect(!model.isPresented)
        #expect(!OnboardingModel(record: record).isPresented)
    }

    @Test
    func walksThroughThePagesInOrder() {
        let model = OnboardingModel(record: InMemoryOnboardingRecord())
        #expect(model.pages == [.welcome, .privacy, .systemPermissions])
        #expect(model.currentPage == .welcome)
        #expect(!model.canGoBack)

        model.advance()
        model.advance()

        #expect(model.currentPage == .systemPermissions)
        #expect(model.isOnLastPage)
        model.goBack()
        #expect(model.currentPage == .privacy)
        #expect(model.canGoBack)
    }

    @Test
    func offersTheWayForwardThatFitsThePage() {
        let phone = OnboardingModel(record: InMemoryOnboardingRecord())
        let mac = OnboardingModel(record: InMemoryOnboardingRecord(), systemExtension: wizard(runs: []))
        #expect(phone.forwardAction == .next)

        phone.goForward()
        phone.goForward()
        #expect(phone.forwardAction == .getStarted)
        phone.goForward()
        mac.goForward()
        mac.goForward()
        mac.goForward()

        #expect(!phone.isPresented)
        #expect(mac.currentPage == .systemExtension)
        #expect(mac.forwardAction == .notNow)
        mac.goForward()
        #expect(!mac.isPresented)
    }

    @Test
    func endsWithTheSystemExtensionWhenTheAppNeedsOne() {
        let model = OnboardingModel(record: InMemoryOnboardingRecord(), systemExtension: wizard(runs: []))

        #expect(model.pages == [.welcome, .privacy, .systemPermissions, .systemExtension])
    }

    @Test
    func finishesByItselfOnceTheExtensionIsApproved() async {
        let record = InMemoryOnboardingRecord()
        let model = OnboardingModel(record: record, systemExtension: wizard(runs: [[.needsUserApproval, .completed]]))

        await model.installSystemExtension()

        #expect(!model.isPresented)
        #expect(record.hasCompletedOnboarding())
    }

    @Test
    func staysOpenWhenTheExtensionIsNotInstalled() async {
        let record = InMemoryOnboardingRecord()
        let model = OnboardingModel(
            record: record, systemExtension: wizard(runs: [[.failed(.forbiddenBySystemPolicy)]]))

        await model.installSystemExtension()

        #expect(model.isPresented)
        #expect(model.systemExtension?.step == .failed(.forbiddenBySystemPolicy))
        #expect(!record.hasCompletedOnboarding())
    }

    @Test
    func activatesTheExtensionAtLaunchOnlyAfterOnboarding() async {
        let firstLaunch = ScriptedSystemExtensionActivator(runs: [[.completed]])
        let laterLaunch = ScriptedSystemExtensionActivator(runs: [[.completed]])
        let newUser = OnboardingModel(record: InMemoryOnboardingRecord(), systemExtension: wizard(firstLaunch))
        let returningUser = OnboardingModel(
            record: InMemoryOnboardingRecord(hasCompletedOnboarding: true),
            systemExtension: wizard(laterLaunch)
        )

        await newUser.activateSystemExtensionOnLaunch()
        await returningUser.activateSystemExtensionOnLaunch()

        #expect(firstLaunch.requestCount == 0)
        #expect(laterLaunch.requestCount == 1)
        #expect(returningUser.systemExtension?.step == .ready)
    }

    private func wizard(runs: [[SystemExtensionActivationEvent]]) -> SystemExtensionWizardModel {
        wizard(ScriptedSystemExtensionActivator(runs: runs))
    }

    private func wizard(_ activator: ScriptedSystemExtensionActivator) -> SystemExtensionWizardModel {
        SystemExtensionWizardModel(activate: EnsureSystemExtensionActivatedUseCase(activator: activator))
    }
}
