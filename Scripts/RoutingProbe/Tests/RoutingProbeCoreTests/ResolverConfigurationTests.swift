import RoutingProbeCore
import Testing

@Suite
struct ResolverConfigurationTests {
    @Test
    func takesTheFirstNameserver() {
        let text = "#\n# macOS Notice\n#\nsearch local\nnameserver 192.168.64.1\nnameserver 2001:db8::53\n"

        #expect(ResolverConfiguration.firstNameserver(in: text) == "192.168.64.1")
    }

    @Test
    func hasNoNameserverInAnEmptyConfiguration() {
        #expect(ResolverConfiguration.firstNameserver(in: "search local\n") == nil)
    }
}
