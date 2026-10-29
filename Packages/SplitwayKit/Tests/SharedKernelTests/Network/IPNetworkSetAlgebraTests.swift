import SharedKernel
import SharedKernelTestSupport
import Testing

@Suite
struct IPNetworkSetAlgebraTests {
    private static let seeds: ClosedRange<UInt64> = 1...100
    private static let sampledAddressCount = 64
    private static let maximumNetworksPerSet = 6

    @Test(arguments: IPAddressFamily.allCases, seeds)
    func differenceAndIntersectionPartitionTheFirstSet(family: IPAddressFamily, seed: UInt64) throws {
        var generator = SeededRandomNumberGenerator(seed: seed)
        let first = try randomSet(of: family, using: &generator)
        let second = try randomSet(of: family, using: &generator)

        #expect(first.subtracting(second).union(first.intersection(second)) == first)
        #expect(first.subtracting(second).isDisjoint(with: second))
        #expect(first.isDisjoint(with: second) == first.intersection(second).networks.isEmpty)
        #expect(first.union(second) == second.union(first))
    }

    @Test(arguments: IPAddressFamily.allCases, seeds)
    func membershipFollowsBooleanLogic(family: IPAddressFamily, seed: UInt64) throws {
        var generator = SeededRandomNumberGenerator(seed: seed)
        let first = try randomSet(of: family, using: &generator)
        let second = try randomSet(of: family, using: &generator)
        let boundaryAddresses = (first.networks + second.networks).flatMap { [$0.firstAddress, $0.lastAddress] }
        let randomAddresses = (0..<Self.sampledAddressCount).map { _ in randomAddress(of: family, using: &generator) }

        for address in boundaryAddresses + randomAddresses {
            let isInFirst = first.contains(address)
            let isInSecond = second.contains(address)
            #expect(first.union(second).contains(address) == (isInFirst || isInSecond))
            #expect(first.intersection(second).contains(address) == (isInFirst && isInSecond))
            #expect(first.subtracting(second).contains(address) == (isInFirst && !isInSecond))
        }
    }

    @Test(arguments: IPAddressFamily.allCases, seeds)
    func decompositionIsOrderedDisjointAndLossless(family: IPAddressFamily, seed: UInt64) throws {
        var generator = SeededRandomNumberGenerator(seed: seed)
        let set = try randomSet(of: family, using: &generator)
        let networks = set.networks

        #expect(networks.allSatisfy { !$0.hasHostBits })
        #expect(zip(networks, networks.dropFirst()).allSatisfy { earlier, later in earlier < later })
        #expect(zip(networks, networks.dropFirst()).allSatisfy { earlier, later in !earlier.overlaps(later) })
        #expect(IPNetworkSet(networks) == set)
    }

    private func randomSet(
        of family: IPAddressFamily,
        using generator: inout SeededRandomNumberGenerator
    ) throws -> IPNetworkSet {
        let networkCount = Int.random(in: 1...Self.maximumNetworksPerSet, using: &generator)
        let networks = try (0..<networkCount).map { _ in
            try IPNetwork(
                address: randomAddress(of: family, using: &generator),
                prefixLength: Int.random(in: 1...family.bitWidth, using: &generator)
            )
        }
        return IPNetworkSet(networks)
    }

    private func randomAddress(
        of family: IPAddressFamily,
        using generator: inout SeededRandomNumberGenerator
    ) -> IPAddress {
        switch family {
        case .ipv4: .ipv4(UInt32.random(in: 0...UInt32.max, using: &generator))
        case .ipv6: .ipv6(UInt128.random(in: 0...UInt128.max, using: &generator))
        }
    }
}
