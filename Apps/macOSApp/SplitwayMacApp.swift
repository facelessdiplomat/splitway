import MenuBarPresentation
import SettingsPresentation
import SwiftUI

@main
struct SplitwayMacApp: App {
    private let composition = AppComposition(configuration: AppConfiguration(bundle: .main))

    var body: some Scene {
        SplitwayRootScene(composition: composition)
        Settings {
            SettingsScreen(presenter: composition.settings)
        }
        SplitwayMenuBar(model: composition.menuBar, mainWindowIdentifier: SplitwayRootScene.mainWindowIdentifier)
    }
}
