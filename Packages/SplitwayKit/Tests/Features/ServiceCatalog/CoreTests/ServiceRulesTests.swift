import ServiceCatalog
import SharedKernel
import Testing

@Suite
struct ServiceRulesTests {
    @Test
    func needsAtLeastOneRule() {
        #expect(throws: ServiceRulesError.empty) {
            try ServiceRules(domainSuffixes: [], networks: [])
        }
    }

    @Test
    func keepsOnlyTheShortestDomainSuffixes() throws {
        let rules = try ServiceRules(
            domainSuffixes: [try DomainName("web.telegram.org"), try DomainName("telegram.org")],
            networks: []
        )

        #expect(rules.domainSuffixes == [try DomainName("telegram.org")])
    }

    @Test
    func mergesAdjacentNetworks() throws {
        let rules = try ServiceRules(
            domainSuffixes: [],
            networks: [try IPNetwork("91.108.4.0/23"), try IPNetwork("91.108.6.0/23")]
        )

        #expect(rules.networks == [try IPNetwork("91.108.4.0/22")])
    }
}
