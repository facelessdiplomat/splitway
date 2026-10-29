import SwiftUI

struct OnboardingView: View {
    private static let maximumWidth: CGFloat = 520

    let model: OnboardingModel

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            OnboardingPageView(model: model)
            Spacer(minLength: 0)
            OnboardingButtons(model: model)
        }
        .padding()
        .frame(maxWidth: Self.maximumWidth)
        .interactiveDismissDisabled()
    }
}
