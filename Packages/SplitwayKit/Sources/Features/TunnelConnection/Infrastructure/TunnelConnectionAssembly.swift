import ProviderMessaging
import TunnelConnection

public struct TunnelConnectionAssembly: Sendable {
    private let providerBundleIdentifier: String
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
        self.providerBundleIdentifier = providerBundleIdentifier
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

    public var readSlotState: ReadSlotStateUseCase {
        ReadSlotStateUseCase(controller: controller)
    }

    public var fetchStatistics: FetchRuntimeStatisticsUseCase {
        FetchRuntimeStatisticsUseCase(messenger: messenger)
    }

    public var activityProbe: ConnectionActivityProbe {
        ConnectionActivityProbe(controller: controller, coordinator: coordinator)
    }

    public func removeSystemConfigurations() async throws(ConnectionFailure) {
        var failure: ConnectionFailure?
        do {
            try await ProviderSlotRemoval<PacketTunnelSlot>(providerBundleIdentifier: providerBundleIdentifier)
                .removeConfigurations()
        } catch {
            failure = error
        }
        #if os(macOS)
            do {
                try await ProviderSlotRemoval<TransparentProxySlot>(providerBundleIdentifier: providerBundleIdentifier)
                    .removeConfigurations()
            } catch {
                failure = error
            }
        #endif
        if let failure {
            throw failure
        }
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
