import TunnelConnection

public struct TunnelConnectionAssembly: Sendable {
    private let controller: any SystemTunnelController
    private let coordinator: ConnectionCoordinator
    private let messenger: PacketTunnelSlotMessenger

    public init(
        providerBundleIdentifier: String,
        wrappingController wrap: (any SystemTunnelController) -> any SystemTunnelController = { controller in
            controller
        }
    ) {
        controller = wrap(Self.systemSlots(providerBundleIdentifier: providerBundleIdentifier))
        coordinator = ConnectionCoordinator(controller: controller)
        messenger = PacketTunnelSlotMessenger(providerBundleIdentifier: providerBundleIdentifier)
    }

    private static func systemSlots(providerBundleIdentifier: String) -> any SystemTunnelController {
        let packetTunnel = ProviderSlotController<PacketTunnelSlot>(providerBundleIdentifier: providerBundleIdentifier)
        #if os(macOS)
            return SlotSelectingTunnelController(
                packetTunnel: packetTunnel,
                transparentProxy: ProviderSlotController<TransparentProxySlot>(
                    providerBundleIdentifier: providerBundleIdentifier
                )
            )
        #else
            return packetTunnel
        #endif
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
