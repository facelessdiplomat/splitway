import DesignSystemPresentation
import SwiftUI

struct ServicePickerRowView: View {
    let row: ServicePickerRow
    let setSelected: @MainActor (Bool) -> Void

    var body: some View {
        Toggle(isOn: isSelected) {
            HStack(spacing: 12) {
                ServiceIconView(icon: row.service.icon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: row.service.displayName)
                    Text(verbatim: rulesSummary)
                        .font(.caption)
                        .foregroundStyle(.supportingText)
                        .lineLimit(1)
                }
            }
        }
        .accessibilityLabel(Text(verbatim: row.service.displayName))
        .accessibilityHint(Text(verbatim: rulesSummary))
    }

    private var rulesSummary: String {
        let rules = row.service.rules
        return (rules.domainSuffixes.map(\.description) + rules.networks.map(\.description)).joined(separator: ", ")
    }

    private var isSelected: Binding<Bool> {
        Binding {
            row.isSelected
        } set: { isSelected in
            setSelected(isSelected)
        }
    }
}
