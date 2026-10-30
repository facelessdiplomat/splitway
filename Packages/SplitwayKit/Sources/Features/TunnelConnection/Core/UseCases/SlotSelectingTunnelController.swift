import AppRouting
import TunnelLibrary

public actor SlotSelectingTunnelController: SystemTunnelController {
    private enum Slot: CaseIterable {
        case packetTunnel
        case transparentProxy
    }

    private let packetTunnel: any SystemTunnelController
    private let transparentProxy: any SystemTunnelController
    private var selectedSlot: Slot?

    public init(packetTunnel: any SystemTunnelController, transparentProxy: any SystemTunnelController) {
        self.packetTunnel = packetTunnel
        self.transparentProxy = transparentProxy
    }

    public func installedTunnel() async -> TunnelIdentifier? {
        await controller(of: selected()).installedTunnel()
    }

    public func currentStatus() async -> SystemConnectionStatus {
        await controller(of: selected()).currentStatus()
    }

    public nonisolated func statusUpdates() -> AsyncStream<SystemConnectionStatus> {
        let (updates, subscriber) = AsyncStream<SystemConnectionStatus>.makeStream()
        let forwarding = Task {
            await withDiscardingTaskGroup { group in
                for slot in Slot.allCases {
                    group.addTask {
                        for await status in self.controller(of: slot).statusUpdates() {
                            await self.forward(status, of: slot, to: subscriber)
                        }
                    }
                }
            }
            subscriber.finish()
        }
        subscriber.onTermination = { _ in forwarding.cancel() }
        return updates
    }

    public func lastDisconnectFailure() async -> ConnectionFailure? {
        await controller(of: selected()).lastDisconnectFailure()
    }

    public func install(_ tunnel: Tunnel) async throws(ConnectionFailure) {
        let slot = Self.slot(for: tunnel)
        for otherSlot in Slot.allCases where otherSlot != slot {
            let other = controller(of: otherSlot)
            if await other.currentStatus().isActive {
                await other.stop()
            }
        }
        selectedSlot = slot
        try await controller(of: slot).install(tunnel)
    }

    public func start() async throws(ConnectionFailure) {
        try await controller(of: selected()).start()
    }

    public func stop() async {
        for slot in Slot.allCases {
            await controller(of: slot).stop()
        }
    }

    private func forward(
        _ status: SystemConnectionStatus,
        of slot: Slot,
        to subscriber: AsyncStream<SystemConnectionStatus>.Continuation
    ) async {
        if await selected() != slot {
            guard status.isActive else { return }
            selectedSlot = slot
        }
        subscriber.yield(status)
    }

    private func selected() async -> Slot {
        if let selectedSlot {
            return selectedSlot
        }
        let isProxyActive = await transparentProxy.currentStatus().isActive
        let slot = selectedSlot ?? (isProxyActive ? .transparentProxy : .packetTunnel)
        selectedSlot = slot
        return slot
    }

    private nonisolated func controller(of slot: Slot) -> any SystemTunnelController {
        switch slot {
        case .packetTunnel: packetTunnel
        case .transparentProxy: transparentProxy
        }
    }

    private static func slot(for tunnel: Tunnel) -> Slot {
        tunnel.routingPolicy.mode.kind == .selectedApplications ? .transparentProxy : .packetTunnel
    }
}
