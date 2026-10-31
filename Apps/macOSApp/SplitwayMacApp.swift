import MenuBarInfrastructure
import MenuBarPresentation
import SettingsPresentation
import SwiftUI

@main
struct SplitwayMacApp: App {
    private let composition: AppComposition
    private let menuBar: MenuBarModel

    init() {
        let composition = AppComposition(configuration: AppConfiguration(bundle: .main))
        self.composition = composition
        menuBar = MenuBarModel(
            tunnels: composition.tunnelList,
            quitConfirmation: AppKitQuitConfirmation(),
            lifecycle: AppKitApplicationLifecycle()
        )
    }

    var body: some Scene {
        SplitwayRootScene(composition: composition)
        Settings {
            SettingsScreen(presenter: composition.settings)
        }
        SplitwayMenuBar(model: menuBar, mainWindowIdentifier: SplitwayRootScene.mainWindowIdentifier)
    }
}
