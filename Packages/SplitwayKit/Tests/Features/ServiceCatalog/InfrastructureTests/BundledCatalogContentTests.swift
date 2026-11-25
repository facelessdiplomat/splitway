import ServiceCatalog
import ServiceCatalogInfrastructure
import Testing

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
}
