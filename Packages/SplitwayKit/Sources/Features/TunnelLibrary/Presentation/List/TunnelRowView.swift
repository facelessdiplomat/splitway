import DesignSystemPresentation
import SwiftUI

struct TunnelRowView: View {
    let row: TunnelRow
    let toggleConnection: @MainActor () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(verbatim: row.name)
                    .font(.headline)
                if let routingMode = row.routingMode {
                    routingMode.title
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                StatusBadge(row.status.title, tone: row.status.tone)
            }
            Spacer()
            TunnelConnectionToggle(row: row, toggleConnection: toggleConnection) {
                Text(verbatim: row.name)
            }
            .labelsHidden()
        }
    }
}
