import SwiftUI

struct SettingsSheet: ViewModifier {
    @Bindable var presenter: SettingsPresenter

    func body(content: Content) -> some View {
        content.sheet(isPresented: $presenter.isShowing) {
            SettingsScreen(presenter: presenter) {
                presenter.isShowing = false
            }
        }
    }
}
