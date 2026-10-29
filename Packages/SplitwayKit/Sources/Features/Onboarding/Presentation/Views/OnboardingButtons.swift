import SwiftUI

struct OnboardingButtons: View {
    let model: OnboardingModel

    var body: some View {
        HStack {
            if model.canGoBack {
                Button {
                    model.goBack()
                } label: {
                    Text("Back", bundle: .module)
                }
            }
            Spacer()
            Button {
                model.goForward()
            } label: {
                forwardTitle
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
    }

    private var forwardTitle: Text {
        switch model.forwardAction {
        case .next: Text("Continue", bundle: .module)
        case .getStarted: Text("Get Started", bundle: .module)
        case .notNow: Text("Not Now", bundle: .module)
        }
    }
}
