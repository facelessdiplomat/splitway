public struct IPNetworkSet: Sendable, Hashable {
    private let ipv4Ranges: AddressRanges
    private let ipv6Ranges: AddressRanges

    public init() {
        self.init(ipv4Ranges: AddressRanges(), ipv6Ranges: AddressRanges())
    }

    public init(_ networks: some Sequence<IPNetwork>) {
        let networksByFamily = Dictionary(grouping: networks, by: \.family)
        self.init(
            ipv4Ranges: AddressRanges(merging: networksByFamily[.ipv4, default: []].map(\.addressRange)),
            ipv6Ranges: AddressRanges(merging: networksByFamily[.ipv6, default: []].map(\.addressRange))
        )
    }

    private init(ipv4Ranges: AddressRanges, ipv6Ranges: AddressRanges) {
        self.ipv4Ranges = ipv4Ranges
        self.ipv6Ranges = ipv6Ranges
    }

    public var isEmpty: Bool {
        ipv4Ranges.isEmpty && ipv6Ranges.isEmpty
    }

    public var networks: [IPNetwork] {
        ipv4Ranges.networks(in: .ipv4) + ipv6Ranges.networks(in: .ipv6)
    }

    public func contains(_ address: IPAddress) -> Bool {
        ranges(of: address.family).contains(address.value)
    }

    public func contains(_ network: IPNetwork) -> Bool {
        ranges(of: network.family).contains(network.addressRange)
    }

    public func isDisjoint(with other: IPNetworkSet) -> Bool {
        intersection(other).isEmpty
    }

    public func union(_ other: IPNetworkSet) -> IPNetworkSet {
        combined(with: other) { own, foreign in own.union(foreign) }
    }

    public func intersection(_ other: IPNetworkSet) -> IPNetworkSet {
        combined(with: other) { own, foreign in own.intersection(foreign) }
    }

    public func subtracting(_ other: IPNetworkSet) -> IPNetworkSet {
        combined(with: other) { own, foreign in own.subtracting(foreign) }
    }

    private func combined(
        with other: IPNetworkSet,
        using operation: (AddressRanges, AddressRanges) -> AddressRanges
    ) -> IPNetworkSet {
        IPNetworkSet(
            ipv4Ranges: operation(ipv4Ranges, other.ipv4Ranges),
            ipv6Ranges: operation(ipv6Ranges, other.ipv6Ranges)
        )
    }

    private func ranges(of family: IPAddressFamily) -> AddressRanges {
        switch family {
        case .ipv4: ipv4Ranges
        case .ipv6: ipv6Ranges
        }
    }
}
