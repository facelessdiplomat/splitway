import DesignSystemPresentation
import SwiftUI

struct OnboardingIntroduction: View {
    private static let spacing: CGFloat = 16

    let page: OnboardingPage

    var body: some View {
        VStack(spacing: Self.spacing) {
            Image(systemName: page.symbolName)
                .font(.system(.largeTitle))
                .imageScale(.large)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            page.title
                .font(.title.bold())
                .multilineTextAlignment(.center)
            page.message
                .font(.body)
                .foregroundStyle(.supportingText)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }
}
