import AppRoutingPresentation
import DesignSystemPresentation
import SwiftUI

struct TunnelRowView: View {
    let row: TunnelRow
    let toggleConnection: @MainActor () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading) {
                details
                connectionToggle
            }
        } else {
            HStack {
                details
                Spacer()
                connectionToggle
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading) {
            Text(verbatim: row.name)
                .font(.headline)
            if let routingMode = row.routingMode {
                routingMode.title
                    .font(.subheadline)
                    .foregroundStyle(.supportingText)
            }
            StatusBadge(row.status.title, tone: row.status.tone)
        }
        .accessibilityElement(children: .combine)
    }

    private var connectionToggle: some View {
        TunnelConnectionToggle(row: row, toggleConnection: toggleConnection) {
            Text(verbatim: row.name)
        }
        .labelsHidden()
    }
}
