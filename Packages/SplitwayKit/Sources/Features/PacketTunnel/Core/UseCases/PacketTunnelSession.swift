import AppRouting
import TunnelConfiguration
import TunnelEngine

public actor PacketTunnelSession {
    private let engine: any WireGuardDeviceEngine
    private let interfaceLocator: any TunnelInterfaceLocator
    private let endpointResolution: ResolveTunnelEndpointsUseCase
    private let pathMonitor: any NetworkPathMonitor
    private let routingPlanner: PlanTunnelRoutingUseCase
    private var configuration: TunnelConfiguration?
    private var routing: TunnelRouting?
    private var device: (any RunningTunnelInterfaceDevice)?
    private var isStopRequested = false
    private var pathObservation: Task<Void, Never>?

    public init(
        engine: any WireGuardDeviceEngine,
        interfaceLocator: any TunnelInterfaceLocator,
        endpointResolver: any EndpointResolver,
        pathMonitor: any NetworkPathMonitor,
        routingPlanner: PlanTunnelRoutingUseCase
    ) {
        self.engine = engine
        self.interfaceLocator = interfaceLocator
        endpointResolution = ResolveTunnelEndpointsUseCase(resolver: endpointResolver)
        self.pathMonitor = pathMonitor
        self.routingPlanner = routingPlanner
    }

    public var isRunning: Bool {
        device != nil
    }

    public func prepareStart(
        configuration: TunnelConfiguration,
        routedBy policy: RoutingPolicy
    ) async throws(PacketTunnelError) -> PreparedTunnelStart {
        let routing = try await routingPlanner.execute(configuration: configuration, policy: policy)
        let endpoints = try await resolvedEndpoints(of: configuration)
        try throwIfStopRequested()
        return PreparedTunnelStart(routing: routing, configuration: configuration, endpoints: endpoints)
    }

    public func completeStart(_ preparedStart: PreparedTunnelStart) throws(PacketTunnelError) {
        try throwIfStopRequested()
        guard let descriptor = interfaceLocator.tunnelFileDescriptor() else { throw .tunnelInterfaceUnavailable }
        let uapi = UAPIConfigurationEncoder.encode(
            preparedStart.configuration, resolvedEndpoints: preparedStart.endpoints)
        let startedDevice = try startedDevice(on: descriptor, configuration: uapi)
        do {
            try route(preparedStart.routing, through: startedDevice)
        } catch {
            startedDevice.stop()
            throw error
        }
        device = startedDevice
        configuration = preparedStart.configuration
        routing = preparedStart.routing
        observePathChanges()
    }

    public func routingChange(to policy: RoutingPolicy) async throws(PacketTunnelError) -> TunnelRoutingChange {
        guard let configuration, let current = routing, device != nil else { throw .notRunning }
        guard policy.mode.kind == current.mode else { throw .routingModeChangeNeedsRestart }
        let changed = try await routingPlanner.execute(configuration: configuration, policy: policy)
        return TunnelRoutingChange(
            routing: changed,
            changedNetworkPlan: changed.networkPlan == current.networkPlan ? nil : changed.networkPlan
        )
    }

    public func complete(_ change: TunnelRoutingChange) throws(PacketTunnelError) {
        guard let device else { throw .notRunning }
        try route(change.routing, through: device)
        routing = change.routing
    }

    public func stop() {
        isStopRequested = true
        pathObservation?.cancel()
        pathObservation = nil
        device?.stop()
        device = nil
    }

    public func handle(_ path: NetworkPathStatus) async {
        guard path == .available, let configuration, device != nil else { return }
        let endpoints = await endpointResolution.reachableEndpoints(of: configuration)
        guard let device else { return }
        if let update = UAPIConfigurationEncoder.endpointUpdate(for: configuration, resolvedEndpoints: endpoints) {
            try? device.apply(update)
        }
        try? device.bumpSockets()
    }

    public func wake() {
        try? device?.bumpSockets()
    }

    public func runtimeStatistics() throws(PacketTunnelError) -> RuntimeStatistics {
        guard let device else { throw .notRunning }
        do {
            return try device.runtimeStatistics()
        } catch {
            throw .engineFailed(error)
        }
    }

    private func resolvedEndpoints(
        of configuration: TunnelConfiguration
    ) async throws(PacketTunnelError) -> [PublicKey: ResolvedEndpoint] {
        do {
            return try await endpointResolution.allEndpoints(of: configuration)
        } catch {
            throw .endpointUnresolvable
        }
    }

    private func startedDevice(
        on descriptor: Int32,
        configuration: UAPIConfiguration
    ) throws(PacketTunnelError) -> any RunningTunnelInterfaceDevice {
        do {
            return try engine.startDevice(tunnelFileDescriptor: descriptor, configuration: configuration)
        } catch {
            throw .engineFailed(error)
        }
    }

    private func route(
        _ routing: TunnelRouting,
        through device: any RunningTunnelInterfaceDevice
    ) throws(PacketTunnelError) {
        guard let translation = routing.translation else { return }
        do {
            try device.applyServiceRouting(translation)
        } catch {
            throw .engineFailed(error)
        }
    }

    private func throwIfStopRequested() throws(PacketTunnelError) {
        guard !isStopRequested else { throw .cancelled }
    }

    private func observePathChanges() {
        let updates = pathMonitor.pathUpdates()
        pathObservation = Task { [weak self] in
            for await path in updates {
                await self?.handle(path)
            }
        }
    }

}
