import SwiftUI

public struct EmptyStateView<Actions: View>: View {
    private let title: Text
    private let systemImage: String
    private let message: Text
    private let actions: Actions

    public init(_ title: Text, systemImage: String, message: Text, @ViewBuilder actions: () -> Actions) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
        self.actions = actions()
    }

    public var body: some View {
        ContentUnavailableView {
            Label {
                title
            } icon: {
                Image(systemName: systemImage)
            }
        } description: {
            message
        } actions: {
            actions
        }
    }
}

#Preview("Empty state") {
    EmptyStateView(
        Text(verbatim: "No tunnels"),
        systemImage: "network.slash",
        message: Text(verbatim: "Import a WireGuard configuration to get started.")
    ) {
        Button {
        } label: {
            Text(verbatim: "Import from file")
        }
        .buttonStyle(.borderedProminent)
    }
}
