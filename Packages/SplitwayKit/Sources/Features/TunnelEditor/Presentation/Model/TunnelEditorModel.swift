import AppRouting
import AppRoutingPresentation
import ApplicationCatalogPresentation
import Observation
import ServiceCatalogPresentation
import TunnelConfiguration
import TunnelEditor
import TunnelLibrary

@MainActor
@Observable
public final class TunnelEditorModel: Identifiable {
    public private(set) var draft: TunnelDraft
    public private(set) var mode = TunnelEditorMode.form
    public private(set) var rawText = ""
    public private(set) var isPrivateKeyRevealed = false
    public private(set) var isSaving = false
    public private(set) var isConfirmingRestart = false
    public private(set) var failure: TunnelEditorFailure?
    public internal(set) var applicationPicker: ApplicationPickerModel?
    public internal(set) var servicePicker: ServicePickerModel?
    public let routing: RoutingSectionModel

    private let editedTunnel: Tunnel?
    private let actions: TunnelEditorActions
    let applicationPickerActions: ApplicationPickerActions?
    let servicePickerActions: ServicePickerActions?
    private let didSave: @MainActor (Tunnel) async -> Void

    public init(
        newTunnelNamed name: String,
        routingPlatform: RoutingPlatform = .current,
        actions: TunnelEditorActions,
        applicationPicker: ApplicationPickerActions? = nil,
        servicePicker: ServicePickerActions? = nil,
        didSave: @escaping @MainActor (Tunnel) async -> Void
    ) {
        var draft = TunnelDraft(name: name, text: "")
        draft.generatePrivateKey()
        self.draft = draft
        editedTunnel = nil
        routing = RoutingSectionModel(policy: .default, platform: routingPlatform)
        self.actions = actions
        applicationPickerActions = applicationPicker
        servicePickerActions = servicePicker
        self.didSave = didSave
        isPrivateKeyRevealed = true
    }

    public init(
        editing tunnel: Tunnel,
        routingPlatform: RoutingPlatform = .current,
        actions: TunnelEditorActions,
        applicationPicker: ApplicationPickerActions? = nil,
        servicePicker: ServicePickerActions? = nil,
        didSave: @escaping @MainActor (Tunnel) async -> Void
    ) {
        draft = TunnelDraft(name: tunnel.name, configuration: tunnel.configuration)
        editedTunnel = tunnel
        routing = RoutingSectionModel(policy: tunnel.routingPolicy, platform: routingPlatform)
        self.actions = actions
        applicationPickerActions = applicationPicker
        servicePickerActions = servicePicker
        self.didSave = didSave
    }

    public var isNewTunnel: Bool {
        editedTunnel == nil
    }

    public var validation: TunnelDraftValidation {
        currentDraft.validation
    }

    public var canSave: Bool {
        let validation = validation
        return validation.problems.isEmpty && validation.configuration != nil && !isSaving
    }

    public var textIssues: [ConfigurationIssue] {
        WgQuickConfigurationParser.parse(rawText).issues
    }

    public func text(for field: TunnelDraftField) -> String {
        draft.text(for: field)
    }

    public func setText(_ text: String, for field: TunnelDraftField) {
        draft.setText(text, for: field)
    }

    public func problems(for field: TunnelDraftField) -> [TunnelDraftProblemReason] {
        validation.problems(for: field).map(\.reason)
    }

    @discardableResult
    public func addPeer() -> PeerDraftID {
        draft.addPeer()
    }

    public func removePeer(_ id: PeerDraftID) {
        draft.removePeer(id)
    }

    public func generatePrivateKey() {
        draft.generatePrivateKey()
        isPrivateKeyRevealed = true
    }

    public func revealPrivateKey() {
        isPrivateKeyRevealed = true
    }

    public func privateNetworkChoice() -> PrivateNetworkChoice {
        draft.privateNetworkChoice()
    }

    public func setExcludesPrivateNetworks(_ excludesPrivateNetworks: Bool) {
        draft.setExcludesPrivateNetworks(excludesPrivateNetworks)
    }

    public func showText() {
        rawText = draft.text
        mode = .text
    }

    public func showForm() {
        draft = currentDraft
        mode = .form
    }

    public func setRawText(_ text: String) {
        rawText = text
    }

    public func save() async {
        guard canSave else { return }
        if let editedTunnel, await actions.activityProbe.isActive(editedTunnel.id) {
            let configuration = currentDraft.validation.configuration
            if LiveRoutingChange.isPossible(from: editedTunnel, to: configuration, routedBy: routing.policy) {
                await performSave(.applyingRoutingPolicy)
            } else {
                isConfirmingRestart = true
            }
            return
        }
        await performSave(.keepingConnection)
    }

    public func confirmRestart() async {
        isConfirmingRestart = false
        await performSave(.restartingConnection)
    }

    public func cancelRestart() {
        isConfirmingRestart = false
    }

    public func dismissFailure() {
        failure = nil
    }

    var currentDraft: TunnelDraft {
        guard mode == .text else { return draft }
        var textDraft = draft
        textDraft.replaceConfiguration(withText: rawText)
        return textDraft
    }

    private func performSave(_ connectionChange: TunnelEditorConnectionChange) async {
        let validation = currentDraft.validation
        guard let name = validation.name, let configuration = validation.configuration else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let saved = try await savedTunnel(named: name, configuration: configuration)
            switch connectionChange {
            case .keepingConnection:
                break
            case .restartingConnection:
                await actions.deactivateTunnel.execute()
                try await restart(saved)
            case .applyingRoutingPolicy:
                guard (try? await actions.applyRoutingPolicy.execute(saved)) != nil else {
                    isConfirmingRestart = true
                    return
                }
            }
            await didSave(saved)
        } catch {
            failure = error
        }
    }

    private func savedTunnel(
        named name: TunnelName,
        configuration: TunnelConfiguration
    ) async throws(TunnelEditorFailure) -> Tunnel {
        do {
            guard let editedTunnel else {
                return try await actions.createTunnel.execute(
                    name: name,
                    configuration: configuration,
                    routingPolicy: routing.policy
                )
            }
            let updated = try await actions.updateTunnel.execute(
                id: editedTunnel.id,
                configuration: configuration,
                routingPolicy: routing.policy
            )
            guard name != editedTunnel.name else { return updated }
            return updated.renamed(to: try await actions.renameTunnel.execute(id: editedTunnel.id, to: name))
        } catch {
            throw .saving(error)
        }
    }

    private func restart(_ tunnel: Tunnel) async throws(TunnelEditorFailure) {
        do {
            try await actions.activateTunnel.execute(tunnel)
        } catch {
            throw .restarting(error)
        }
    }
}
