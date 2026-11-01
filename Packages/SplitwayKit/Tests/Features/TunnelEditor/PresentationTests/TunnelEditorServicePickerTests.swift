import AppRouting
import ServiceCatalog
import ServiceCatalogPresentation
import ServiceCatalogTestSupport
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEditorPresentation

@MainActor
@Suite
struct TunnelEditorServicePickerTests {
    @Test
    func offersThePickerOnceSelectedServicesAreRouted() async throws {
        let environment = TunnelEditorTestEnvironment()
        let tunnel = try await environment.storeTunnel(named: "Office")
        let editor = environment.editor(for: tunnel, choosingServicesWith: try pickerActions())
        #expect(!editor.canChooseServices)

        editor.routing.selectMode(.selectedServices)

        #expect(editor.canChooseServices)
    }

    @Test
    func offersNoPickerWithoutTheServiceCatalog() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(for: try await environment.storeTunnel(named: "Office"))

        editor.routing.selectMode(.selectedServices)
        editor.chooseServices()

        #expect(!editor.canChooseServices)
        #expect(editor.servicePicker == nil)
    }

    @Test
    func opensThePickerWithTheServicesAlreadyRouted() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(
            for: try await environment.storeTunnel(named: "Office"),
            choosingServicesWith: try pickerActions()
        )
        editor.routing.selectMode(.selectedServices)
        let selection = ServiceSelection([try ServiceIdentifier("telegram")])
        editor.routing.setServices(selection)

        editor.chooseServices()

        #expect(editor.servicePicker?.selection == selection)
    }

    @Test
    func savesTheServicesChosenInThePicker() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(
            for: try await environment.storeTunnel(named: "Office"),
            choosingServicesWith: try pickerActions()
        )
        editor.routing.selectMode(.selectedServices)
        editor.chooseServices()
        let picker = try #require(editor.servicePicker)
        await picker.load()
        picker.setSelected(true, id: try ServiceIdentifier("telegram"))

        editor.finishChoosingServices()
        await editor.save()

        #expect(editor.servicePicker == nil)
        #expect(environment.savedTunnels.map(\.routingPolicy.mode) == [.selectedServices(picker.selection)])
    }

    @Test
    func checksTheChosenServicesAgainstTheConfigurationBeingEdited() async throws {
        let environment = TunnelEditorTestEnvironment()
        let editor = environment.editor(
            for: try await environment.storeTunnel(named: "Office"),
            choosingServicesWith: try pickerActions()
        )
        editor.showText()
        editor.setRawText(WgQuickFixtures.multiplePeers)
        editor.routing.selectMode(.selectedServices)
        editor.routing.setServices(ServiceSelection([try ServiceIdentifier("telegram")]))

        editor.chooseServices()
        let picker = try #require(editor.servicePicker)
        await picker.load()

        #expect(picker.warnings.contains { warning in warning.warning == .allowedIPsWithoutDefaultRoute })
    }

    private func pickerActions() throws -> ServicePickerActions {
        let telegram = try ServiceCatalogFixtures.profile(
            id: "telegram", name: "Telegram", domains: ["telegram.org"], networks: ["91.108.4.0/22"])
        return ServicePickerActions(
            bundled: FixedBundledServiceCatalog(services: [telegram]),
            custom: InMemoryCustomServiceRepository()
        )
    }
}
