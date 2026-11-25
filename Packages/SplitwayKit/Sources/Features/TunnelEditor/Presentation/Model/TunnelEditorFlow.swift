import AppRouting
import AppRoutingPresentation
import ApplicationCatalogPresentation
import Foundation
import Observation
import ServiceCatalogPresentation
import TunnelLibrary

@MainActor
@Observable
public final class TunnelEditorFlow {
    public var editor: TunnelEditorModel?

    let copyToClipboard: @MainActor (String) -> Void
    private let routingPlatform: RoutingPlatform
    private let actions: TunnelEditorActions
    private let applicationPicker: ApplicationPickerActions?
    private let servicePicker: ServicePickerActions?
    private let didSave: @MainActor (Tunnel) async -> Void

    public init(
        routingPlatform: RoutingPlatform = .current,
        actions: TunnelEditorActions,
        applicationPicker: ApplicationPickerActions? = nil,
        servicePicker: ServicePickerActions? = nil,
        copyToClipboard: @escaping @MainActor (String) -> Void,
        didSave: @escaping @MainActor (Tunnel) async -> Void
    ) {
        self.routingPlatform = routingPlatform
        self.actions = actions
        self.applicationPicker = applicationPicker
        self.servicePicker = servicePicker
        self.copyToClipboard = copyToClipboard
        self.didSave = didSave
    }

    public func createTunnel() {
        editor = TunnelEditorModel(
            newTunnelNamed: Self.newTunnelName,
            routingPlatform: routingPlatform,
            actions: actions,
            applicationPicker: applicationPicker,
            servicePicker: servicePicker
        ) { [weak self] tunnel in
            await self?.finish(saving: tunnel)
        }
    }

    public func edit(_ tunnel: Tunnel) {
        editor = TunnelEditorModel(
            editing: tunnel,
            routingPlatform: routingPlatform,
            actions: actions,
            applicationPicker: applicationPicker,
            servicePicker: servicePicker
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
