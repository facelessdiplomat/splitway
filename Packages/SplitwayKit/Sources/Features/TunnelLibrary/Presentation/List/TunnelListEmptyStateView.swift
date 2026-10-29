import DesignSystemPresentation
import SwiftUI

struct TunnelListEmptyStateView: View {
    let addition: TunnelAdditionOptions

    var body: some View {
        EmptyStateView(
            Text("No tunnels yet", bundle: .module),
            systemImage: "network",
            message: Text("Import a WireGuard configuration to get started.", bundle: .module)
        ) {
            TunnelAdditionButtons(addition: addition)
                .buttonStyle(.bordered)
        }
    }
}
