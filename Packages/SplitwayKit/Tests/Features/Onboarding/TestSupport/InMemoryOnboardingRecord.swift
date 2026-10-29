import Onboarding
import Synchronization

public final class InMemoryOnboardingRecord: OnboardingRecord {
    private let isCompleted: Mutex<Bool>

    public init(hasCompletedOnboarding: Bool = false) {
        isCompleted = Mutex(hasCompletedOnboarding)
    }

    public func hasCompletedOnboarding() -> Bool {
        isCompleted.withLock { isCompleted in isCompleted }
    }

    public func recordCompletedOnboarding() {
        isCompleted.withLock { isCompleted in isCompleted = true }
    }
}
