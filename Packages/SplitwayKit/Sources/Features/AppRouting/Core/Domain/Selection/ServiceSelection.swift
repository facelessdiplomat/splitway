public struct ServiceSelection: Sendable, Hashable {
    public let services: [ServiceIdentifier]

    public init(_ services: [ServiceIdentifier]) {
        var seenServices: Set<ServiceIdentifier> = []
        self.services = services.filter { service in seenServices.insert(service).inserted }
    }

    public var isEmpty: Bool {
        services.isEmpty
    }
}
