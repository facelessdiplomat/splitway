import Observation
import Onboarding
import SystemExtensionPresentation

@MainActor
@Observable
public final class OnboardingModel {
    private static let introductionPages: [OnboardingPage] = [.welcome, .privacy, .systemPermissions]

    public let pages: [OnboardingPage]
    public let systemExtension: SystemExtensionWizardModel?
    public private(set) var currentPage = OnboardingPage.welcome
    public private(set) var isPresented: Bool

    private let record: any OnboardingRecord

    public init(record: any OnboardingRecord, systemExtension: SystemExtensionWizardModel? = nil) {
        self.record = record
        self.systemExtension = systemExtension
        pages = Self.introductionPages + (systemExtension == nil ? [] : [.systemExtension])
        isPresented = !record.hasCompletedOnboarding()
    }

    public var canGoBack: Bool {
        currentIndex > 0
    }

    public var isOnLastPage: Bool {
        currentIndex == pages.count - 1
    }

    public var forwardAction: OnboardingForwardAction {
        if currentPage == .systemExtension {
            return .notNow
        }
        return isOnLastPage ? .getStarted : .next
    }

    public func goForward() {
        switch forwardAction {
        case .next: advance()
        case .getStarted, .notNow: finish()
        }
    }

    public func advance() {
        guard !isOnLastPage else { return }
        currentPage = pages[currentIndex + 1]
    }

    public func goBack() {
        guard canGoBack else { return }
        currentPage = pages[currentIndex - 1]
    }

    public func installSystemExtension() async {
        guard let systemExtension else { return }
        await systemExtension.install()
        if systemExtension.step == .ready {
            finish()
        }
    }

    public func activateSystemExtensionOnLaunch() async {
        guard !isPresented, let systemExtension else { return }
        await systemExtension.install()
    }

    public func finish() {
        record.recordCompletedOnboarding()
        isPresented = false
    }

    private var currentIndex: Int {
        pages.firstIndex(of: currentPage) ?? 0
    }
}
