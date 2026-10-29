import DesignSystemPresentation
import SwiftUI

struct ImportPreviewView: View {
    let model: ImportPreviewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if let summary = model.summary {
                Section {
                    Label {
                        summary.message
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            if !model.rows.isEmpty {
                Section {
                    ForEach(model.rows) { row in
                        ImportCandidateRowView(row: row, model: model)
                    }
                } header: {
                    Text("Configurations", bundle: .module)
                        .foregroundStyle(.supportingText)
                }
            }
            if !model.failures.isEmpty {
                Section {
                    ForEach(Array(model.failures.enumerated()), id: \.offset) { _, failure in
                        VStack(alignment: .leading) {
                            failure.source.title
                            failure.reason.message
                                .font(.subheadline)
                                .foregroundStyle(.supportingText)
                        }
                    }
                } header: {
                    Text("Not imported", bundle: .module)
                        .foregroundStyle(.supportingText)
                }
            }
        }
        .navigationTitle(Text("Import Tunnels", bundle: .module))
        .toolbar {
            ImportPreviewToolbar(model: model) {
                dismiss()
            }
        }
        .alert(Text("Couldn’t import", bundle: .module), isPresented: isShowingImportError) {
            Button(role: .cancel) {
                model.dismissImportError()
            } label: {
                Text("OK", bundle: .module)
            }
        } message: {
            Text("The tunnel storage couldn’t be read or written. Try again.", bundle: .module)
        }
    }

    private var isShowingImportError: Binding<Bool> {
        Binding {
            model.importError != nil
        } set: { isPresented in
            if !isPresented {
                model.dismissImportError()
            }
        }
    }
}
