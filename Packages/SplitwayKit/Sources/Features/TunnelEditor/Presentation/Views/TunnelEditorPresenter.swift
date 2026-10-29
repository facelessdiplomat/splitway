import SwiftUI

struct TunnelEditorPresenter: ViewModifier {
    @Bindable var flow: TunnelEditorFlow

    func body(content: Content) -> some View {
        content.sheet(item: $flow.editor) { editor in
            NavigationStack {
                TunnelEditorView(model: editor, copyToClipboard: flow.copyToClipboard) {
                    flow.editor = nil
                }
            }
            .interactiveDismissDisabled()
        }
    }
}
