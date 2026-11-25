struct ServicePathSnapshot: Sendable {
    static let selectedAddressService = "https://api.ipify.org"
    static let otherAddressService = "https://icanhazip.com"

    let selectedAddress: String
    let otherAddress: String
    let resolverEcho: [String]

    static func measure() async throws -> ServicePathSnapshot {
        async let selected = ServiceRoutingProbe.text(at: selectedAddressService)
        async let other = ServiceRoutingProbe.text(at: otherAddressService)
        let resolverEcho = await Task.detached { ResolverIdentityProbe.resolverEcho() }.value
        return ServicePathSnapshot(
            selectedAddress: try await selected,
            otherAddress: try await other,
            resolverEcho: resolverEcho
        )
    }
}
