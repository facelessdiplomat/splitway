import SwiftUI

struct OnboardingPresenter: ViewModifier {
    private static let minimumWidth: CGFloat = 480
    private static let minimumHeight: CGFloat = 420

    let model: OnboardingModel

    func body(content: Content) -> some View {
        #if os(iOS)
            content.fullScreenCover(isPresented: isPresented) {
                OnboardingView(model: model)
            }
        #else
            content.sheet(isPresented: isPresented) {
                OnboardingView(model: model)
                    .frame(minWidth: Self.minimumWidth, minHeight: Self.minimumHeight)
            }
        #endif
    }

    private var isPresented: Binding<Bool> {
        Binding {
            model.isPresented
        } set: { _ in
        }
    }
}
