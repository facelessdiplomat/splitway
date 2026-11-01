import AppRouting

public struct ServiceCatalog: Sendable, Hashable {
    public let services: [ServiceProfile]

    public init(services: [ServiceProfile]) {
        var seen = Set<ServiceIdentifier>()
        self.services = services.filter { service in seen.insert(service.id).inserted }
    }

    public func service(_ identifier: ServiceIdentifier) -> ServiceProfile? {
        services.first { service in service.id == identifier }
    }

    public func services(in selection: ServiceSelection) -> [ServiceProfile] {
        let selected = Set(selection.services)
        return services.filter { service in selected.contains(service.id) }
    }
}
