import SwiftUI

public struct SettingsScreen: View {
    private static let minimumWidth: CGFloat = 460
    private static let minimumHeight: CGFloat = 360

    private let presenter: SettingsPresenter
    private let close: (@MainActor () -> Void)?

    public init(presenter: SettingsPresenter) {
        self.init(presenter: presenter, close: nil)
    }

    init(presenter: SettingsPresenter, close: (@MainActor () -> Void)?) {
        self.presenter = presenter
        self.close = close
    }

    public var body: some View {
        NavigationStack {
            SettingsForm(
                version: presenter.version,
                notices: presenter.notices,
                loginItem: presenter.loginItem,
                uninstall: presenter.uninstall
            )
            .navigationTitle(Text("Settings", bundle: .module))
            .toolbar {
                if let close {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .close) {
                            close()
                        }
                        .keyboardShortcut(.cancelAction)
                    }
                }
            }
        }
        #if os(macOS)
            .frame(minWidth: Self.minimumWidth, minHeight: Self.minimumHeight)
        #endif
    }
}
