import DesignSystemPresentation
import SwiftUI

struct TunnelDetailView: View {
    let row: TunnelRow
    let toggleConnection: @MainActor () -> Void

    var body: some View {
        Form {
            Section {
                TunnelConnectionToggle(row: row, toggleConnection: toggleConnection) {
                    Text("Connection", bundle: .module)
                }
                HStack {
                    Text("Status", bundle: .module)
                    Spacer()
                    StatusBadge(row.status.title, tone: row.status.tone)
                }
                .alignmentGuide(.listRowSeparatorLeading) { dimensions in dimensions[.leading] }
                if let routingMode = row.routingMode {
                    KeyValueRow(Text("Routing", bundle: .module), value: routingMode.title)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(Text(verbatim: row.name))
    }
}
