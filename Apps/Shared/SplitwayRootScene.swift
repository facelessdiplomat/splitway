import SwiftUI
import TunnelImportInfrastructure
import TunnelImportPresentation
import TunnelLibraryPresentation

struct SplitwayRootScene: Scene {
    let composition: AppComposition

    var body: some Scene {
        WindowGroup {
            TunnelLibraryRootView(
                model: composition.tunnelList,
                statistics: composition.statistics,
                addition: TunnelAdditionOptions(methods: AppComposition.additionMethods) { method in
                    composition.add(method)
                }
            )
            .tunnelImport(composition.tunnelImport)
            .dropDestination(for: DroppedImportFile.self) { files, _ in
                Task.immediate { await composition.tunnelImport.importDropped(files.map(\.payload)) }
                return !files.isEmpty
            }
            .onOpenURL { url in
                Task.immediate { await composition.tunnelImport.importFiles([url]) }
            }
        }
    }
}
