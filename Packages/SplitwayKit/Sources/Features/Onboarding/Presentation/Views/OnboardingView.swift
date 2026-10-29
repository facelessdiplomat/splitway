import DesignSystemPresentation
import SwiftUI

struct OnboardingView: View {
    private static let maximumWidth: CGFloat = 520

    let model: OnboardingModel

    var body: some View {
        VStack {
            OverflowScrollView {
                OnboardingPageView(model: model)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
            OnboardingButtons(model: model)
        }
        .padding()
        .frame(maxWidth: Self.maximumWidth)
        .interactiveDismissDisabled()
    }
}
