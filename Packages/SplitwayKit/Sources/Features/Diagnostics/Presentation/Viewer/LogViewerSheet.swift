import SwiftUI

struct LogViewerSheet: ViewModifier {
    private static let minimumWidth: CGFloat = 560
    private static let minimumHeight: CGFloat = 440

    @Bindable var presenter: LogViewerPresenter

    func body(content: Content) -> some View {
        content.sheet(isPresented: $presenter.isShowing) {
            NavigationStack {
                LogViewerView(model: presenter.model) {
                    presenter.isShowing = false
                }
            }
            .frame(minWidth: Self.minimumWidth, minHeight: Self.minimumHeight)
        }
    }
}
