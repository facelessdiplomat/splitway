import SwiftUI
import TunnelConfigurationPresentation
import TunnelLibrary

struct ImportCandidateRowView: View {
    let row: ImportPreviewRow
    let model: ImportPreviewModel

    var body: some View {
        VStack(alignment: .leading) {
            Toggle(isOn: isSelected) {
                TextField(text: name) {
                    Text("Tunnel name", bundle: .module)
                }
            }
            .disabled(!row.isImportable || model.summary != nil)
            row.source.title
                .font(.caption)
                .foregroundStyle(.secondary)
            if row.hasInvalidName {
                Text("Enter a name of up to \(TunnelName.maximumLength) characters.", bundle: .module)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            } else if row.importsUnderAnotherName, let importName = row.importName {
                Text("Will be imported as “\(importName)”", bundle: .module)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let alreadyImportedAs = row.alreadyImportedAs {
                Label {
                    Text("Already in the library as “\(alreadyImportedAs)”", bundle: .module)
                } icon: {
                    Image(systemName: "doc.on.doc")
                }
                .font(.subheadline)
                .foregroundStyle(.orange)
            }
            ForEach(Array((row.errors + row.warnings).enumerated()), id: \.offset) { _, issue in
                ConfigurationIssueLabel(issue)
            }
        }
    }

    private var isSelected: Binding<Bool> {
        Binding {
            row.isSelected
        } set: { isSelected in
            model.setSelected(isSelected, for: row)
        }
    }

    private var name: Binding<String> {
        Binding {
            row.name
        } set: { text in
            model.rename(row, to: text)
        }
    }
}
