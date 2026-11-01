import DesignSystemPresentation
import SwiftUI

struct UnansweredHandshakeWarning: View {
    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text("The server is not responding", bundle: .module)
                    .font(.headline)
                Text(
                    "No handshake since connecting. Check the server address and keys, or try another network.",
                    bundle: .module
                )
                .foregroundStyle(.supportingText)
            }
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
        .accessibilityElement(children: .combine)
    }
}
