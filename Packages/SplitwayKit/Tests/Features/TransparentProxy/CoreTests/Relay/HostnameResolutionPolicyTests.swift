import SharedKernel
import Testing
import TransparentProxy

@Suite
struct HostnameResolutionPolicyTests {
    private static let systemAddress = IPAddress.ipv4(0xCB00_7107)

    @Test
    func resolvesTheHostnameOfAFlowThroughTheTunnel() throws {
        let policy = try Self.policy(resolvesNamesThroughTunnel: true)

        let target = policy.target(forHostname: "Example.com.", address: Self.systemAddress)

        #expect(target == .hostname(try DomainName("example.com")))
    }

    @Test(arguments: [
        nil, "", "203.0.113.7", "2001:db8::7", "[2001:db8::7]", "printer.local", "NAS.Local.", "bad name",
    ])
    func connectsToTheAddressWhenTheHostnameIsNotAResolvableName(hostname: String?) throws {
        let policy = try Self.policy(resolvesNamesThroughTunnel: true)

        #expect(policy.target(forHostname: hostname, address: Self.systemAddress) == .address(Self.systemAddress))
    }

    @Test
    func connectsToTheAddressWhenTheTunnelCannotResolveNames() throws {
        let policy = try Self.policy(resolvesNamesThroughTunnel: false)

        #expect(policy.target(forHostname: "example.com", address: Self.systemAddress) == .address(Self.systemAddress))
    }

    @Test
    func picksTheFirstResolvedAddressOfTheSystemsFamilyInsideTheTunnel() throws {
        let policy = try Self.policy(resolvesNamesThroughTunnel: true)
        let resolved = [try IPAddress("2001:db8::5"), try IPAddress("10.0.0.5"), try IPAddress("198.51.100.5")]

        #expect(
            policy.address(choosingFrom: resolved, insteadOf: Self.systemAddress) == (try IPAddress("198.51.100.5")))
    }

    @Test
    func keepsTheSystemsAddressWhenTheTunnelAnswersWithItToo() throws {
        let policy = try Self.policy(resolvesNamesThroughTunnel: true)
        let resolved = [try IPAddress("198.51.100.5"), Self.systemAddress]

        #expect(policy.address(choosingFrom: resolved, insteadOf: Self.systemAddress) == Self.systemAddress)
    }

    @Test
    func keepsTheSystemsAddressWhenNoResolvedAddressFits() throws {
        let policy = try Self.policy(resolvesNamesThroughTunnel: true)
        let outsideTheTunnel = [try IPAddress("10.0.0.5"), try IPAddress("2001:db8::5")]

        #expect(policy.address(choosingFrom: outsideTheTunnel, insteadOf: Self.systemAddress) == Self.systemAddress)
        #expect(policy.address(choosingFrom: [], insteadOf: Self.systemAddress) == Self.systemAddress)
    }

    private static func policy(resolvesNamesThroughTunnel: Bool) throws -> HostnameResolutionPolicy {
        let tunnelNetworks = IPNetworkSet([try IPNetwork("128.0.0.0/1"), try IPNetwork("2001:db8::/32")])
        return HostnameResolutionPolicy(
            tunnelNetworks: tunnelNetworks,
            resolvesNamesThroughTunnel: resolvesNamesThroughTunnel
        )
    }
}
