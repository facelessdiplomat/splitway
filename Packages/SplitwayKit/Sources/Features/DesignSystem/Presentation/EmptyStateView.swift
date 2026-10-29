import SwiftUI

public struct EmptyStateView<Actions: View>: View {
    private static var spacing: CGFloat { 12 }

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
        OverflowScrollView {
            VStack(spacing: Self.spacing) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(.supportingText)
                    .accessibilityHidden(true)
                title
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                message
                    .foregroundStyle(.supportingText)
                actions
            }
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
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
