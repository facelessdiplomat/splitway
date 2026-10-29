import SwiftUI
import TunnelLibraryPresentation

struct SplitwayRootScene: Scene {
    let composition: AppComposition

    var body: some Scene {
        WindowGroup {
            TunnelLibraryRootView(
                model: composition.tunnelList,
                statistics: composition.statistics,
                addition: TunnelAdditionOptions(methods: []) { _ in }
            )
        }
    }
}
