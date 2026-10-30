import ProviderMessaging
import TunnelConnection

public struct TunnelConnectionAssembly: Sendable {
    private let controller: any SystemTunnelController
    private let coordinator: ConnectionCoordinator
    private let messenger: any ProviderMessenger

    public init(
        providerBundleIdentifier: String,
        wrappingController wrap: (any SystemTunnelController) -> any SystemTunnelController = { controller in
            controller
        }
    ) {
        let slots = Self.systemSlots(providerBundleIdentifier: providerBundleIdentifier)
        controller = wrap(slots.controller)
        coordinator = ConnectionCoordinator(controller: controller)
        messenger = slots.messenger
    }

    public var activateTunnel: ActivateTunnelUseCase {
        ActivateTunnelUseCase(coordinator: coordinator)
    }

    public var deactivateTunnel: DeactivateTunnelUseCase {
        DeactivateTunnelUseCase(coordinator: coordinator)
    }

    public var applyRoutingPolicy: ApplyRoutingPolicyUseCase {
        ApplyRoutingPolicyUseCase(messenger: messenger)
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

    private static func systemSlots(
        providerBundleIdentifier: String
    ) -> (controller: any SystemTunnelController, messenger: any ProviderMessenger) {
        let packetTunnel = ProviderSlotController<PacketTunnelSlot>(providerBundleIdentifier: providerBundleIdentifier)
        let packetTunnelMessenger = ProviderSlotMessenger<PacketTunnelSlot>(
            providerBundleIdentifier: providerBundleIdentifier)
        #if os(macOS)
            let slots = SlotSelectingTunnelController(
                packetTunnel: packetTunnel,
                transparentProxy: ProviderSlotController<TransparentProxySlot>(
                    providerBundleIdentifier: providerBundleIdentifier
                )
            )
            let messenger = SlotSelectingMessenger(
                selection: slots,
                packetTunnel: packetTunnelMessenger,
                transparentProxy: ProviderSlotMessenger<TransparentProxySlot>(
                    providerBundleIdentifier: providerBundleIdentifier
                )
            )
            return (slots, messenger)
        #else
            return (packetTunnel, packetTunnelMessenger)
        #endif
    }
}
