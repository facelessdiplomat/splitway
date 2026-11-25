import ServiceCatalog

public struct ServicePickerWarning: Sendable, Hashable {
    public let warning: ServiceRoutingWarning
    public let serviceName: String?

    public init(warning: ServiceRoutingWarning, serviceName: String?) {
        self.warning = warning
        self.serviceName = serviceName
    }
}
