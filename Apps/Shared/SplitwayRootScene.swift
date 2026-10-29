import SwiftUI
import TunnelLibraryPresentation

struct SplitwayRootScene: Scene {
    let composition: AppComposition

    var body: some Scene {
        WindowGroup {
            TunnelLibraryRootView(
                model: composition.tunnelList,
                addition: TunnelAdditionOptions(methods: []) { _ in }
            )
        }
    }
}
