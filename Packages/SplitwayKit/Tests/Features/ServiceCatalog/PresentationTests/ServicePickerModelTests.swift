import AppRouting
import ServiceCatalog
import ServiceCatalogPresentation
import ServiceCatalogTestSupport
import SharedKernel
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport

@MainActor
@Suite
struct ServicePickerModelTests {
    @Test
    func groupsTheServicesByCategoryInCatalogOrder() async throws {
        let services = try StarterServices()
        let picker = ServicePickerTestEnvironment(services: services.all).picker()

        await picker.load()

        #expect(picker.sections.map(\.category) == [.messaging, .video])
        #expect(picker.sections.first?.rows.map(\.service.id) == [services.telegram.id, services.signal.id])
    }

    @Test
    func findsServicesByNameOrDomain() async throws {
        let services = try StarterServices()
        let picker = ServicePickerTestEnvironment(services: services.all).picker()
        await picker.load()

        picker.searchText = "tele"
        let byName = picker.sections.flatMap(\.rows).map(\.service.id)
        picker.searchText = "youtu.be"
        let byDomain = picker.sections.flatMap(\.rows).map(\.service.id)

        #expect(byName == [services.telegram.id])
        #expect(byDomain == [services.youtube.id])
    }

    @Test
    func selectsAndDeselectsServicesAndReportsEveryChange() async throws {
        let services = try StarterServices()
        let environment = ServicePickerTestEnvironment(services: services.all)
        let picker = environment.picker()
        await picker.load()

        picker.setSelected(true, id: services.telegram.id)
        picker.setSelected(true, id: services.youtube.id)
        picker.setSelected(false, id: services.telegram.id)

        #expect(picker.selection == ServiceSelection([services.youtube.id]))
        #expect(environment.reportedSelections.last == ServiceSelection([services.youtube.id]))
        #expect(environment.reportedSelections.count == 3)
        #expect(picker.sections.flatMap(\.rows).filter(\.isSelected).map(\.service.id) == [services.youtube.id])
    }

    @Test
    func explainsWhatTheTunnelCannotRouteForTheSelection() async throws {
        let telegram = try ServiceCatalogFixtures.profile(
            id: "telegram", name: "Telegram", domains: ["telegram.org"], networks: ["91.108.4.0/22"])
        let corporate = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.multiplePeers).configuration)
        let picker = ServicePickerTestEnvironment(services: [telegram]).picker(selecting: [telegram.id], for: corporate)

        await picker.load()

        #expect(
            picker.warnings == [
                ServicePickerWarning(
                    warning: .networksOutsideAllowedIPs(telegram.id, [try IPNetwork("91.108.4.0/22")]),
                    serviceName: "Telegram"
                ),
                ServicePickerWarning(warning: .allowedIPsWithoutDefaultRoute, serviceName: nil),
                ServicePickerWarning(warning: .resolverOutsideAllowedIPs(try IPAddress("1.1.1.1")), serviceName: nil),
            ]
        )
    }

    @Test
    func selectsACustomServiceOnceItIsSaved() async throws {
        let picker = ServicePickerTestEnvironment(services: try StarterServices().all).picker()
        await picker.load()

        picker.addCustomService()
        let editor = try #require(picker.customServiceEditor)
        editor.name = "Work"
        editor.domainsText = "corp.example"
        await editor.save()

        let work = try #require(picker.sections.last?.rows.first)
        #expect(picker.customServiceEditor == nil)
        #expect(picker.sections.last?.category == .custom)
        #expect(work.service.displayName == "Work")
        #expect(work.isSelected)
    }

    @Test
    func renamesACustomServiceInPlace() async throws {
        let work = try await ServiceCatalogFixtures.customService(name: "Work")
        let picker = ServicePickerTestEnvironment(services: [], customServices: [work]).picker(selecting: [work.id])
        await picker.load()

        picker.editCustomService(work.id)
        let editor = try #require(picker.customServiceEditor)
        editor.name = "Office"
        await editor.save()

        #expect(picker.sections.flatMap(\.rows).map(\.service.displayName) == ["Office"])
        #expect(picker.selection == ServiceSelection([work.id]))
    }

    @Test
    func forgetsADeletedCustomService() async throws {
        let work = try await ServiceCatalogFixtures.customService(name: "Work")
        let environment = ServicePickerTestEnvironment(services: [], customServices: [work])
        let picker = environment.picker(selecting: [work.id])
        await picker.load()

        await picker.deleteCustomService(work.id)

        #expect(picker.sections.isEmpty)
        #expect(picker.selection.services.isEmpty)
        #expect(await environment.repository.services.isEmpty)
    }

    @Test
    func reportsACatalogItCannotRead() async throws {
        let picker = ServicePickerTestEnvironment(unreadableCustomServicesWith: try StarterServices().all).picker()

        await picker.load()

        #expect(picker.isCatalogUnavailable)
        #expect(picker.sections.isEmpty)
    }
}

private struct StarterServices {
    let telegram: ServiceProfile
    let youtube: ServiceProfile
    let signal: ServiceProfile

    init() throws {
        telegram = try ServiceCatalogFixtures.profile(
            id: "telegram", name: "Telegram", domains: ["telegram.org", "t.me"])
        youtube = try ServiceCatalogFixtures.profile(
            id: "youtube", name: "YouTube", category: .video, domains: ["youtube.com", "youtu.be"])
        signal = try ServiceCatalogFixtures.profile(id: "signal", name: "Signal", domains: ["signal.org"])
    }

    var all: [ServiceProfile] {
        [telegram, youtube, signal]
    }
}
