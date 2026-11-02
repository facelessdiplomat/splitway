import SwiftUI

struct LogViewerToolbar: ToolbarContent {
    let model: LogViewerModel
    let close: @MainActor () -> Void
    let confirmClearing: @MainActor () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(role: .close) {
                close()
            }
            .keyboardShortcut(.cancelAction)
        }
        ToolbarItem(placement: .primaryAction) {
            LogViewerFilterMenu(model: model)
        }
        #if os(iOS)
            ToolbarItem(placement: .secondaryAction) {
                LogViewerActionButton(action: .export, model: model, confirmClearing: confirmClearing)
            }
            ToolbarItem(placement: .secondaryAction) {
                LogViewerActionButton(action: .sendReport, model: model, confirmClearing: confirmClearing)
            }
            ToolbarItem(placement: .secondaryAction) {
                LogViewerActionButton(action: .clear, model: model, confirmClearing: confirmClearing)
            }
        #endif
    }
}
