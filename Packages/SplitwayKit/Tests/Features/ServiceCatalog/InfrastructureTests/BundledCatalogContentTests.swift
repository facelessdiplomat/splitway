import AppRouting
import ServiceCatalog
import ServiceCatalogInfrastructure
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@Suite
struct BundledCatalogContentTests {
    private static let startingServices = [
        "telegram", "whatsapp", "signal", "instagram", "facebook", "threads", "youtube", "x", "discord", "chatgpt",
        "claude", "spotify", "netflix", "linkedin", "github",
    ]

    @Test
    func listsTheFifteenStartingServicesInOrder() throws {
        let services = try BundledServiceCatalogRepository.bundled.loadServices()

        #expect(services.map(\.id.description) == Self.startingServices)
    }

    @Test
    func givesEveryServiceDomainsAndASource() throws {
        let services = try BundledServiceCatalogRepository.bundled.loadServices()

        for service in services {
            #expect(!service.rules.domainSuffixes.isEmpty, "\(service.id) has no domain suffixes")
            #expect(!service.notes.isEmpty, "\(service.id) does not name its source")
        }
    }

    @Test
    func compilesEveryServiceWithoutWarningsThroughATunnelOfAllTraffic() throws {
        let catalog = ServiceCatalog(services: try BundledServiceCatalogRepository.bundled.loadServices())
        let configuration = try #require(
            WgQuickConfigurationParser.parse(Self.allTrafficConfiguration).configuration
        )

        for service in catalog.services {
            let plan = ServiceRoutingPlanCompiler().compile(
                selection: ServiceSelection([service.id]), catalog: catalog, configuration: configuration)

            #expect(plan.warnings.isEmpty, "\(service.id) compiles with warnings: \(plan.warnings)")
            #expect(!plan.matchDomains.isEmpty, "\(service.id) has no domains to match")
        }
    }

    private static let allTrafficConfiguration = [
        "[Interface]", "PrivateKey = \(SampleKeys.interfacePrivateKeyText)", "Address = 10.14.0.2/16, fd00::2/64",
        "DNS = 10.64.0.1", "[Peer]", "PublicKey = \(SampleKeys.firstPeerPublicKeyText)",
        "AllowedIPs = 0.0.0.0/0, ::/0", "Endpoint = 203.0.113.10:51820",
    ].joined(separator: "\n")
}
