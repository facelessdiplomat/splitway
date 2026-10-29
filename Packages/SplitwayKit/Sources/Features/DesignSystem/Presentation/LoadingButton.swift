import SwiftUI

public struct LoadingButton<Label: View>: View {
    private let isLoading: Bool
    private let action: @MainActor () -> Void
    private let label: Label

    public init(isLoading: Bool, action: @escaping @MainActor () -> Void, @ViewBuilder label: () -> Label) {
        self.isLoading = isLoading
        self.action = action
        self.label = label()
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                label.opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel(Text("Loading", bundle: .module))
                }
            }
        }
        .disabled(isLoading)
    }
}

#Preview("Loading buttons") {
    VStack {
        LoadingButton(isLoading: false, action: {}) {
            Text(verbatim: "Connect")
        }
        LoadingButton(isLoading: true, action: {}) {
            Text(verbatim: "Connect")
        }
    }
    .buttonStyle(.borderedProminent)
    .padding()
}
