import Foundation
import Onboarding
import OnboardingInfrastructure
import Testing

@Suite
final class UserDefaultsOnboardingRecordTests {
    private let suiteName = "UserDefaultsOnboardingRecordTests-\(UUID().uuidString)"

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    @Test
    func remembersThatOnboardingWasCompleted() {
        let record = UserDefaultsOnboardingRecord(suiteName: suiteName)
        #expect(!record.hasCompletedOnboarding())

        record.recordCompletedOnboarding()

        #expect(UserDefaultsOnboardingRecord(suiteName: suiteName).hasCompletedOnboarding())
    }
}
