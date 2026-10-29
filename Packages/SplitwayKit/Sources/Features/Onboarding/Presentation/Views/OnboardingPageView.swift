import SwiftUI
import SystemExtensionPresentation

struct OnboardingPageView: View {
    let model: OnboardingModel

    var body: some View {
        switch model.currentPage {
        case .systemExtension:
            if let systemExtension = model.systemExtension {
                SystemExtensionWizardView(model: systemExtension) {
                    await model.installSystemExtension()
                }
            }
        case .welcome, .privacy, .systemPermissions:
            OnboardingIntroduction(page: model.currentPage)
        }
    }
}
