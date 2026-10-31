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
    static let mainWindowIdentifier = "tunnels"
    private static let everyExternalEvent: Set<String> = ["*"]

    let composition: AppComposition

    var body: some Scene {
        WindowGroup(id: Self.mainWindowIdentifier) {
            TunnelLibraryRootView(
                model: composition.tunnelList,
                statistics: composition.statistics,
                addition: addition,
                export: composition.tunnelExport,
                navigation: navigation
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
            .handlesExternalEvents(preferring: Self.everyExternalEvent, allowing: Self.everyExternalEvent)
            .task { await composition.onboarding.activateSystemExtensionOnLaunch() }
        }
        .handlesExternalEvents(matching: Self.everyExternalEvent)
        .commands {
            TunnelLibraryCommands(addition: addition, navigation: navigation)
        }
    }

    private var addition: TunnelAdditionOptions {
        TunnelAdditionOptions(methods: AppComposition.additionMethods) { method in
            composition.add(method)
        }
    }

    private var navigation: TunnelLibraryNavigation {
        TunnelLibraryNavigation(
            editTunnel: { tunnel in composition.tunnelEditor.edit(tunnel) },
            showLog: { composition.logViewer.show() },
            showSettings: showSettings
        )
    }

    private var showSettings: (@MainActor @Sendable () -> Void)? {
        #if os(iOS)
            return { composition.settings.show() }
        #else
            return nil
        #endif
    }
}
