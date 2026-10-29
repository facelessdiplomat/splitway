import SharedKernel

public struct TunnelAddressFamilyPlan: Sendable, Hashable {
    public let addresses: [IPNetwork]
    public let includedRoutes: [IPNetwork]

    public init(addresses: [IPNetwork], includedRoutes: [IPNetwork]) {
        self.addresses = addresses
        self.includedRoutes = includedRoutes
    }
}
