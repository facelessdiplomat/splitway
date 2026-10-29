import DiagnosticsPresentation
import SwiftUI
import TunnelEditorPresentation
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
                },
                export: composition.tunnelExport,
                navigation: TunnelLibraryNavigation { tunnel in
                    composition.tunnelEditor.edit(tunnel)
                } showLog: {
                    composition.logViewer.show()
                }
            )
            .tunnelImport(composition.tunnelImport)
            .tunnelEditor(composition.tunnelEditor)
            .logViewer(composition.logViewer)
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
