import SwiftUI

extension View {
    public func onboarding(_ model: OnboardingModel) -> some View {
        modifier(OnboardingPresenter(model: model))
    }
}
