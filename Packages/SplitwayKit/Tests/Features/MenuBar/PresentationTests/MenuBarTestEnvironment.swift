import AppRouting
import Foundation
import MenuBar
import MenuBarPresentation
import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelConnection
import TunnelConnectionTestSupport
import TunnelLibrary
import TunnelLibraryPresentation
import TunnelLibraryTestSupport

@MainActor
final class RecordingApplicationLifecycle: ApplicationLifecycle {
    private(set) var activationCount = 0
    private(set) var isTerminated = false

    func activate() {
        activationCount += 1
    }

    func terminate() {
        isTerminated = true
    }
}

@MainActor
final class ScriptedQuitConfirmation: QuitConfirmation {
    private let answer: QuitDecision
    private(set) var askedTunnelNames: [String] = []

    init(answer: QuitDecision) {
        self.answer = answer
    }

    func decision(forActiveTunnelNamed name: String) async -> QuitDecision {
        askedTunnelNames.append(name)
        return answer
    }
}

@MainActor
struct MenuBarTestEnvironment {
    static let connectedSince = Date(timeIntervalSince1970: 1_800_000_000)

    let records = InMemoryTunnelRecordRepository()
    let secrets = InMemoryTunnelSecretStore()
    let controller: FakeSystemTunnelController
    let tunnels: TunnelListModel
    let lifecycle = RecordingApplicationLifecycle()
    let confirmation: ScriptedQuitConfirmation
    let model: MenuBarModel

    init(controller: FakeSystemTunnelController = FakeSystemTunnelController(), quitAnswer: QuitDecision = .stay) {
        self.controller = controller
        let coordinator = ConnectionCoordinator(controller: controller)
        tunnels = TunnelListModel(
            library: TunnelLibraryActions(
                loadTunnels: LoadTunnelsUseCase(records: records, secrets: secrets),
                deleteTunnel: DeleteTunnelUseCase(
                    records: records,
                    secrets: secrets,
                    activityProbe: ConnectionActivityProbe(controller: controller, coordinator: coordinator)
                ),
                duplicateTunnel: DuplicateTunnelUseCase(records: records, secrets: secrets),
                reorderTunnels: ReorderTunnelsUseCase(records: records)
            ),
            connection: TunnelConnectionActions(
                activateTunnel: ActivateTunnelUseCase(coordinator: coordinator),
                deactivateTunnel: DeactivateTunnelUseCase(coordinator: coordinator),
                observeConnection: ObserveConnectionStateUseCase(controller: controller)
            )
        )
        confirmation = ScriptedQuitConfirmation(answer: quitAnswer)
        model = MenuBarModel(tunnels: tunnels, quitConfirmation: confirmation, lifecycle: lifecycle)
    }

    @discardableResult
    func storeTunnel(named name: String, routingPolicy: RoutingPolicy = .default) async throws -> Tunnel {
        let configuration = try #require(WgQuickConfigurationParser.parse(WgQuickFixtures.minimal).configuration)
        return try await CreateTunnelUseCase(records: records, secrets: secrets)
            .execute(name: TunnelName(name), configuration: configuration, routingPolicy: routingPolicy)
    }

    func connect(_ tunnel: Tunnel) {
        tunnels.apply(SlotState(tunnelID: tunnel.id, connection: .connected(since: Self.connectedSince)))
    }

    func item(named name: String) throws -> MenuBarTunnel {
        try #require(model.items.first { item in item.name == name })
    }
}
