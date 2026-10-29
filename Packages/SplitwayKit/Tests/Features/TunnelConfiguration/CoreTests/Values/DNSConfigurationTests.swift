import SharedKernel
import Testing
import TunnelConfiguration

@Suite
struct DNSConfigurationTests {
    @Test
    func separatesServersFromSearchDomainsKeepingTheirOrder() throws {
        let configuration = try DNSConfiguration(entries: ["1.1.1.1", "corp.example", "2606:4700:4700::1111", "lan"])

        #expect(configuration.servers == [try IPAddress("1.1.1.1"), try IPAddress("2606:4700:4700::1111")])
        #expect(configuration.searchDomains == [try DomainName("corp.example"), try DomainName("lan")])
    }

    @Test
    func listsServersBeforeSearchDomainsInCanonicalEntries() throws {
        let configuration = try DNSConfiguration(entries: ["corp.example", "1.1.1.1"])

        #expect(configuration.entries == ["1.1.1.1", "corp.example"])
    }

    @Test
    func reportsTheFirstInvalidEntry() {
        #expect(throws: DNSConfigurationParsingError.invalidEntry("exa_mple")) {
            try DNSConfiguration(entries: ["1.1.1.1", "exa_mple", "also_bad"])
        }
    }

    @Test
    func knowsWhenNothingIsConfigured() throws {
        #expect(try DNSConfiguration(entries: []).isEmpty)
        #expect(try !DNSConfiguration(entries: ["lan"]).isEmpty)
    }
}
