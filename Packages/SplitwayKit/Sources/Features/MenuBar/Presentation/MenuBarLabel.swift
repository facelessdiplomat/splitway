import SwiftUI

struct MenuBarLabel: View {
    let model: MenuBarModel
    let mainWindowIdentifier: String

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image(systemName: model.icon.symbolName)
            .accessibilityLabel(model.icon.accessibilityLabel)
            .task { await model.start() }
            .onChange(of: model.isMainWindowRequested) { _, isRequested in
                guard isRequested else { return }
                openWindow(id: mainWindowIdentifier)
                model.mainWindowShown()
            }
    }
}
