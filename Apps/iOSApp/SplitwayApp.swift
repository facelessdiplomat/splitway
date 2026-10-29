import SwiftUI

@main
struct SplitwayApp: App {
    private let composition = AppComposition(configuration: AppConfiguration(bundle: .main))

    var body: some Scene {
        SplitwayRootScene(composition: composition)
    }
}
