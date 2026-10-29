import SwiftUI
import TunnelConfigurationPresentation

struct TunnelTextSection: View {
    private static let editorMinimumHeight: CGFloat = 280

    let model: TunnelEditorModel

    var body: some View {
        Section {
            TextEditor(text: text)
                .font(.body.monospaced())
                .frame(minHeight: Self.editorMinimumHeight)
                .plainTextInput()
        }
        if !model.textIssues.isEmpty {
            Section {
                ForEach(Array(model.textIssues.enumerated()), id: \.offset) { _, issue in
                    ConfigurationIssueLabel(issue)
                }
            } header: {
                Text("Problems", bundle: .module)
            }
        }
    }

    private var text: Binding<String> {
        Binding {
            model.rawText
        } set: { text in
            model.setRawText(text)
        }
    }
}
