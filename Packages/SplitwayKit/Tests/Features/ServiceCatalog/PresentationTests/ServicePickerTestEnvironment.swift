import AppRouting
import ServiceCatalog
import ServiceCatalogPresentation
import ServiceCatalogTestSupport
import Testing
import TunnelConfiguration

@MainActor
final class ServicePickerTestEnvironment {
    let repository: InMemoryCustomServiceRepository
    let actions: ServicePickerActions
    private(set) var reportedSelections: [ServiceSelection] = []

    init(services: [ServiceProfile], customServices: [CustomService] = []) {
        repository = InMemoryCustomServiceRepository(services: customServices)
        actions = ServicePickerActions(bundled: FixedBundledServiceCatalog(services: services), custom: repository)
    }

    init(unreadableCustomServicesWith services: [ServiceProfile]) {
        repository = InMemoryCustomServiceRepository()
        actions = ServicePickerActions(
            bundled: FixedBundledServiceCatalog(services: services),
            custom: UnavailableCustomServiceRepository()
        )
    }

    func picker(
        selecting selection: [ServiceIdentifier] = [],
        for configuration: TunnelConfiguration? = nil
    ) -> ServicePickerModel {
        ServicePickerModel(
            selection: ServiceSelection(selection),
            configuration: configuration,
            actions: actions
        ) { [weak self] selection in
            self?.reportedSelections.append(selection)
        }
    }
}
