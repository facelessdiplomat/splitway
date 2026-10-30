import ApplicationCatalog
import DesignSystemPresentation
import SwiftUI

struct ApplicationPickerRowView: View {
    let row: ApplicationPickerRow
    let iconLoader: any ApplicationIconLoader
    let setSelected: @MainActor (Bool) -> Void

    var body: some View {
        Toggle(isOn: isSelected) {
            HStack(spacing: 10) {
                ApplicationIconView(path: row.id, kind: row.application.kind, iconLoader: iconLoader)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: row.application.name)
                    ForEach(row.remarks, id: \.self) { remark in
                        remark.message
                            .font(.caption)
                            .foregroundStyle(.supportingText)
                    }
                }
                if row.isResolving {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }

    private var isSelected: Binding<Bool> {
        Binding {
            row.isSelected
        } set: { isSelected in
            setSelected(isSelected)
        }
    }
}
