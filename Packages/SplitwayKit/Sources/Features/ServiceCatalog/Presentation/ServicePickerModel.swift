import AppRouting
import Foundation
import Observation
import ServiceCatalog
import TunnelConfiguration

@MainActor
@Observable
public final class ServicePickerModel: Identifiable {
    private static let categoryOrder: [ServiceCategory] = [
        .messaging, .social, .video, .music, .ai, .development, .custom,
    ]

    public private(set) var selection: ServiceSelection
    public private(set) var isLoading = false
    public private(set) var isCatalogUnavailable = false
    public private(set) var customServiceEditor: CustomServiceEditorModel?
    public private(set) var deletionFailure: CustomServiceError?
    public var searchText = ""

    private var services: [ServiceProfile] = []
    private let configuration: TunnelConfiguration?
    private let actions: ServicePickerActions
    private let didChangeSelection: @MainActor (ServiceSelection) -> Void

    public init(
        selection: ServiceSelection,
        configuration: TunnelConfiguration?,
        actions: ServicePickerActions,
        didChangeSelection: @escaping @MainActor (ServiceSelection) -> Void
    ) {
        self.selection = selection
        self.configuration = configuration
        self.actions = actions
        self.didChangeSelection = didChangeSelection
    }

    public var sections: [ServicePickerSection] {
        let selected = Set(selection.services)
        let rows = services.filter(matchesSearch).map { service in
            ServicePickerRow(service: service, isSelected: selected.contains(service.id))
        }
        return Self.categoryOrder.compactMap { category in
            let categoryRows = rows.filter { row in row.service.category == category }
            return categoryRows.isEmpty ? nil : ServicePickerSection(category: category, rows: categoryRows)
        }
    }

    public var warnings: [ServicePickerWarning] {
        guard let configuration, !services.isEmpty else { return [] }
        let plan = actions.compiler.compile(
            selection: selection,
            catalog: ServiceCatalog(services: services),
            configuration: configuration
        )
        return plan.warnings.filter { warning in warning != .emptySelection }.map { warning in
            ServicePickerWarning(warning: warning, serviceName: serviceName(in: warning))
        }
    }

    public func service(withID identifier: ServiceIdentifier) -> ServiceProfile? {
        services.first { service in service.id == identifier }
    }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            services = try await actions.loadCatalog.execute().services
            isCatalogUnavailable = false
        } catch {
            isCatalogUnavailable = true
        }
    }

    public func setSelected(_ isSelected: Bool, id: ServiceIdentifier) {
        guard selection.services.contains(id) != isSelected else { return }
        let services = isSelected ? selection.services + [id] : selection.services.filter { service in service != id }
        selection = ServiceSelection(services)
        didChangeSelection(selection)
    }

    public func addCustomService() {
        customServiceEditor = CustomServiceEditorModel(save: actions.saveCustomService) { [weak self] service in
            self?.add(service)
        }
    }

    public func editCustomService(_ identifier: ServiceIdentifier) {
        guard let profile = service(withID: identifier), profile.category == .custom else { return }
        let save = actions.saveCustomService
        customServiceEditor = CustomServiceEditorModel(editing: profile, save: save) { [weak self] service in
            self?.replace(service)
        }
    }

    public func finishEditingCustomService() {
        customServiceEditor = nil
    }

    public func deleteCustomService(_ identifier: ServiceIdentifier) async {
        do {
            try await actions.deleteCustomService.execute(identifier)
        } catch {
            deletionFailure = error
            return
        }
        services.removeAll { service in service.id == identifier }
        setSelected(false, id: identifier)
    }

    public func dismissDeletionFailure() {
        deletionFailure = nil
    }

    private func add(_ service: CustomService) {
        customServiceEditor = nil
        services.append(service.profile)
        setSelected(true, id: service.id)
    }

    private func replace(_ service: CustomService) {
        customServiceEditor = nil
        guard let index = services.firstIndex(where: { stored in stored.id == service.id }) else { return }
        services[index] = service.profile
    }

    private func matchesSearch(_ service: ServiceProfile) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return service.displayName.localizedStandardContains(query)
            || service.rules.domainSuffixes.contains { domain in domain.description.localizedStandardContains(query) }
    }

    private func serviceName(in warning: ServiceRoutingWarning) -> String? {
        guard case .networksOutsideAllowedIPs(let identifier, _) = warning else { return nil }
        return service(withID: identifier)?.displayName ?? identifier.description
    }
}
