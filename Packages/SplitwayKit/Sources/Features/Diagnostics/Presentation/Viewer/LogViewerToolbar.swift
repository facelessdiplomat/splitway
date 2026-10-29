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
        }
        ToolbarItem(placement: .primaryAction) {
            LogViewerFilterMenu(model: model)
        }
        ToolbarItem(placement: .secondaryAction) {
            Button {
                Task.immediate { await model.prepareExport() }
            } label: {
                Label {
                    Text("Export Log", bundle: .module)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .disabled(model.isLogEmpty)
        }
        ToolbarItem(placement: .secondaryAction) {
            Button(role: .destructive) {
                confirmClearing()
            } label: {
                Label {
                    Text("Clear Log", bundle: .module)
                } icon: {
                    Image(systemName: "trash")
                }
            }
            .disabled(model.isLogEmpty)
        }
    }
}
