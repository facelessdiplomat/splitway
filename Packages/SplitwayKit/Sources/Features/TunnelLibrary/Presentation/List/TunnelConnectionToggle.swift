import SwiftUI

struct TunnelConnectionToggle<Label: View>: View {
    private let row: TunnelRow
    private let toggleConnection: @MainActor () -> Void
    private let label: Label

    init(row: TunnelRow, toggleConnection: @escaping @MainActor () -> Void, @ViewBuilder label: () -> Label) {
        self.row = row
        self.toggleConnection = toggleConnection
        self.label = label()
    }

    var body: some View {
        Toggle(isOn: isConnectionActive) {
            label
        }
        .toggleStyle(.switch)
        .disabled(!row.canToggleConnection)
        .accessibilityHint(Text("Connects or disconnects the tunnel", bundle: .module))
    }

    private var isConnectionActive: Binding<Bool> {
        Binding {
            row.isConnectionActive
        } set: { _ in
            toggleConnection()
        }
    }
}
