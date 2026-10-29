import DiagnosticsPresentation
import OnboardingPresentation
import SettingsPresentation
import SwiftUI
import SystemExtensionPresentation
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
                navigation: TunnelLibraryNavigation(
                    editTunnel: { tunnel in composition.tunnelEditor.edit(tunnel) },
                    showLog: { composition.logViewer.show() },
                    showSettings: showSettings
                )
            )
            .tunnelImport(composition.tunnelImport)
            .tunnelEditor(composition.tunnelEditor)
            .logViewer(composition.logViewer)
            .onboarding(composition.onboarding)
            .systemExtensionAttention(
                composition.onboarding.systemExtension,
                isSuppressed: composition.onboarding.isPresented
            )
            #if os(iOS)
                .settingsSheet(composition.settings)
            #endif
            .dropDestination(for: DroppedImportFile.self) { files, _ in
                Task.immediate { await composition.tunnelImport.importDropped(files.map(\.payload)) }
                return !files.isEmpty
            }
            .onOpenURL { url in
                Task.immediate { await composition.tunnelImport.importFiles([url]) }
            }
            .task { await composition.onboarding.activateSystemExtensionOnLaunch() }
        }
    }

    private var showSettings: (@MainActor @Sendable () -> Void)? {
        #if os(iOS)
            return { composition.settings.show() }
        #else
            return nil
        #endif
    }
}
