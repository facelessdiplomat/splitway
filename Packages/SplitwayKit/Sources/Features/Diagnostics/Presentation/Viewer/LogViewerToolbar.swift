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
    }
}
