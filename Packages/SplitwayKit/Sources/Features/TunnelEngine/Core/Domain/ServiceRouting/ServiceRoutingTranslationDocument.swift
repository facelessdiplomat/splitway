import SharedKernel

struct ServiceRoutingTranslationDocument: Encodable {
    private static let currentVersion = 1

    let version: Int
    let virtualResolver: IPAddress
    let upstreamResolver: IPAddress
    let fakeIPv4Network: IPNetwork
    let fakeIPv6Network: IPNetwork?

    init(_ translation: ServiceRoutingTranslation) {
        version = Self.currentVersion
        virtualResolver = translation.virtualResolver
        upstreamResolver = translation.upstreamResolver
        fakeIPv4Network = translation.fakeIPv4Network
        fakeIPv6Network = translation.fakeIPv6Network
    }
}
