import DesignSystemPresentation
import SwiftUI

struct ImportPreviewToolbar: ToolbarContent {
    let model: ImportPreviewModel
    let close: @MainActor () -> Void

    var body: some ToolbarContent {
        if model.summary == nil {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    close()
                } label: {
                    Text("Cancel", bundle: .module)
                }
                .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                LoadingButton(isLoading: model.isImporting) {
                    Task.immediate { await model.confirm() }
                } label: {
                    Text("Import", bundle: .module)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!model.canImport)
            }
        } else {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    close()
                } label: {
                    Text("Done", bundle: .module)
                }
                .keyboardShortcut(.cancelAction)
            }
        }
    }
}
