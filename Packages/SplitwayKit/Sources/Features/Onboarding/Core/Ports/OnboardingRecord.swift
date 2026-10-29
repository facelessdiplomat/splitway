public protocol OnboardingRecord: Sendable {
    func hasCompletedOnboarding() -> Bool
    func recordCompletedOnboarding()
}
