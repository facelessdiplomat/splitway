import SwiftUI

struct SystemExtensionWizardActions: View {
    private static let extensionSettings = URL(
        string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")

    let step: SystemExtensionWizardStep
    let install: @MainActor () async -> Void
    @Environment(\.openURL) private var openURL

    var body: some View {
        switch step {
        case .introduction:
            installButton(Text("Install", bundle: .module))
        case .installing:
            ProgressView()
        case .awaitingApproval:
            if let settings = Self.extensionSettings {
                Button {
                    openURL(settings)
                } label: {
                    Text("Open System Settings", bundle: .module)
                }
                .buttonStyle(.borderedProminent)
            }
            ProgressView {
                Text("Waiting for your approval…", bundle: .module)
            }
        case .failed:
            installButton(Text("Try Again", bundle: .module))
        case .ready, .restartRequired:
            EmptyView()
        }
    }

    private func installButton(_ title: Text) -> some View {
        Button {
            Task.immediate { await install() }
        } label: {
            title
        }
        .buttonStyle(.borderedProminent)
    }
}
