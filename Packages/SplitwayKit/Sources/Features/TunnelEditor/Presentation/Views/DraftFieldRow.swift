import SwiftUI
import TunnelEditor

struct DraftFieldRow: View {
    let model: TunnelEditorModel
    let field: TunnelDraftField
    let title: Text
    let example: String

    var body: some View {
        VStack(alignment: .leading) {
            LabeledContent {
                TextField(text: text, prompt: Text(verbatim: example)) {
                    title
                }
                .multilineTextAlignment(.trailing)
                .plainTextInput()
            } label: {
                title
            }
            ForEach(Array(model.problems(for: field).enumerated()), id: \.offset) { _, reason in
                reason.message
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var text: Binding<String> {
        Binding {
            model.text(for: field)
        } set: { text in
            model.setText(text, for: field)
        }
    }
}
