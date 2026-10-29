import TunnelConnection

public struct TunnelConnectionAssembly: Sendable {
    private let controller: PacketTunnelSlotController
    private let coordinator: ConnectionCoordinator
    private let messenger: PacketTunnelSlotMessenger

    public init(providerBundleIdentifier: String) {
        controller = PacketTunnelSlotController(providerBundleIdentifier: providerBundleIdentifier)
        coordinator = ConnectionCoordinator(controller: controller)
        messenger = PacketTunnelSlotMessenger(providerBundleIdentifier: providerBundleIdentifier)
    }

    public var activateTunnel: ActivateTunnelUseCase {
        ActivateTunnelUseCase(coordinator: coordinator)
    }

    public var deactivateTunnel: DeactivateTunnelUseCase {
        DeactivateTunnelUseCase(coordinator: coordinator)
    }

    public var observeConnection: ObserveConnectionStateUseCase {
        ObserveConnectionStateUseCase(controller: controller)
    }

    public var fetchStatistics: FetchRuntimeStatisticsUseCase {
        FetchRuntimeStatisticsUseCase(messenger: messenger)
    }

    public var activityProbe: ConnectionActivityProbe {
        ConnectionActivityProbe(controller: controller, coordinator: coordinator)
    }
}
