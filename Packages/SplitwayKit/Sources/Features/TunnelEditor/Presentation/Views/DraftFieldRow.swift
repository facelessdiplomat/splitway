import DesignSystemPresentation
import SwiftUI
import TunnelEditor

struct DraftFieldRow: View {
    let model: TunnelEditorModel
    let field: TunnelDraftField
    let title: Text
    let example: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading) {
            if dynamicTypeSize.isAccessibilitySize {
                title
                textField
                    .multilineTextAlignment(.leading)
            } else {
                LabeledContent {
                    textField
                        .multilineTextAlignment(.trailing)
                } label: {
                    title
                }
            }
            ForEach(Array(model.problems(for: field).enumerated()), id: \.offset) { _, reason in
                reason.message
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var textField: some View {
        TextField(text: text, prompt: Text(verbatim: example)) {
            title
        }
        .accessibilityLabel(title)
        .plainTextInput()
    }

    private var text: Binding<String> {
        Binding {
            model.text(for: field)
        } set: { text in
            model.setText(text, for: field)
        }
    }
}
