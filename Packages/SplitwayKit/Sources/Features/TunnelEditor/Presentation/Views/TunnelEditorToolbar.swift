import DesignSystemPresentation
import SwiftUI

struct TunnelEditorToolbar: ToolbarContent {
    let model: TunnelEditorModel
    let close: @MainActor () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                close()
            } label: {
                Text("Cancel", bundle: .module)
            }
            .keyboardShortcut(.cancelAction)
        }
        ToolbarItem(placement: .principal) {
            Picker(selection: mode) {
                Text("Form", bundle: .module).tag(TunnelEditorMode.form)
                Text("Text", bundle: .module).tag(TunnelEditorMode.text)
            } label: {
                Text("Editing mode", bundle: .module)
            }
            .pickerStyle(.segmented)
        }
        ToolbarItem(placement: .confirmationAction) {
            LoadingButton(isLoading: model.isSaving) {
                Task.immediate { await model.save() }
            } label: {
                Text("Save", bundle: .module)
            }
            .keyboardShortcut("s")
            .disabled(!model.canSave)
        }
    }

    private var mode: Binding<TunnelEditorMode> {
        Binding {
            model.mode
        } set: { mode in
            switch mode {
            case .form: model.showForm()
            case .text: model.showText()
            }
        }
    }
}
