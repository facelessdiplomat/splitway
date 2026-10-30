import SettingsPresentation
import SwiftUI

@main
struct SplitwayMacApp: App {
    private let composition = AppComposition(configuration: AppConfiguration(bundle: .main))

    init() {
        DNSProxySpikeRunner.runIfRequested()
    }

    var body: some Scene {
        SplitwayRootScene(composition: composition)
        Settings {
            SettingsScreen(presenter: composition.settings)
        }
    }
}
