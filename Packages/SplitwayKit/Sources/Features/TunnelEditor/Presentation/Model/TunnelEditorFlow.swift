import AppRouting
import AppRoutingPresentation
import ApplicationCatalogPresentation
import Foundation
import Observation
import TunnelLibrary

@MainActor
@Observable
public final class TunnelEditorFlow {
    public var editor: TunnelEditorModel?

    let copyToClipboard: @MainActor (String) -> Void
    private let actions: TunnelEditorActions
    private let applicationPicker: ApplicationPickerActions?
    private let didSave: @MainActor (Tunnel) async -> Void

    public init(
        actions: TunnelEditorActions,
        applicationPicker: ApplicationPickerActions? = nil,
        copyToClipboard: @escaping @MainActor (String) -> Void,
        didSave: @escaping @MainActor (Tunnel) async -> Void
    ) {
        self.actions = actions
        self.applicationPicker = applicationPicker
        self.copyToClipboard = copyToClipboard
        self.didSave = didSave
    }

    public func createTunnel() {
        editor = TunnelEditorModel(
            newTunnelNamed: Self.newTunnelName,
            actions: actions,
            applicationPicker: applicationPicker
        ) { [weak self] tunnel in
            await self?.finish(saving: tunnel)
        }
    }

    public func edit(_ tunnel: Tunnel) {
        editor = TunnelEditorModel(
            editing: tunnel,
            actions: actions,
            applicationPicker: applicationPicker
        ) { [weak self] tunnel in
            await self?.finish(saving: tunnel)
        }
    }

    private static var newTunnelName: String {
        String(localized: "New tunnel", bundle: .module)
    }

    private func finish(saving tunnel: Tunnel) async {
        editor = nil
        await didSave(tunnel)
    }
}
