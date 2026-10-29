import Foundation
import Onboarding

public struct UserDefaultsOnboardingRecord: OnboardingRecord {
    private static let completedOnboardingKey = "Splitway.hasCompletedOnboarding"

    private let suiteName: String?

    public init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    public func hasCompletedOnboarding() -> Bool {
        defaults.bool(forKey: Self.completedOnboardingKey)
    }

    public func recordCompletedOnboarding() {
        defaults.set(true, forKey: Self.completedOnboardingKey)
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }
}
