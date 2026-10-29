import SwiftUI

@main
struct SplitwayMacApp: App {
    private let composition = AppComposition(configuration: AppConfiguration(bundle: .main))

    var body: some Scene {
        SplitwayRootScene(composition: composition)
    }
}
