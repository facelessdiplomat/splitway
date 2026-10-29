import AppRouting
import TunnelConfiguration
import TunnelEngine

public actor PacketTunnelSession {
    private let engine: any WireGuardDeviceEngine
    private let interfaceLocator: any TunnelInterfaceLocator
    private let endpointResolver: any EndpointResolver
    private let pathMonitor: any NetworkPathMonitor
    private var configuration: TunnelConfiguration?
    private var device: (any RunningWireGuardDevice)?
    private var isStopRequested = false
    private var pathObservation: Task<Void, Never>?

    public init(
        engine: any WireGuardDeviceEngine,
        interfaceLocator: any TunnelInterfaceLocator,
        endpointResolver: any EndpointResolver,
        pathMonitor: any NetworkPathMonitor
    ) {
        self.engine = engine
        self.interfaceLocator = interfaceLocator
        self.endpointResolver = endpointResolver
        self.pathMonitor = pathMonitor
    }

    public var isRunning: Bool {
        device != nil
    }

    public func prepareStart(
        configuration: TunnelConfiguration,
        routedBy policy: RoutingPolicy
    ) async throws(PacketTunnelError) -> PreparedTunnelStart {
        let plan = try Self.networkPlan(for: configuration, routedBy: policy)
        let endpoints = try await resolvedEndpoints(of: configuration)
        try throwIfStopRequested()
        return PreparedTunnelStart(networkPlan: plan, configuration: configuration, endpoints: endpoints)
    }

    public func completeStart(_ preparedStart: PreparedTunnelStart) throws(PacketTunnelError) {
        try throwIfStopRequested()
        guard let descriptor = interfaceLocator.tunnelFileDescriptor() else { throw .tunnelInterfaceUnavailable }
        let uapi = UAPIConfigurationEncoder.encode(
            preparedStart.configuration, resolvedEndpoints: preparedStart.endpoints)
        do {
            device = try engine.startDevice(tunnelFileDescriptor: descriptor, configuration: uapi)
        } catch {
            throw .engineFailed(error)
        }
        configuration = preparedStart.configuration
        observePathChanges()
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
        let endpoints = await reachableEndpoints(of: configuration)
        guard let device else { return }
        try? device.apply(UAPIConfigurationEncoder.encode(configuration, resolvedEndpoints: endpoints))
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
        var resolved: [PublicKey: ResolvedEndpoint] = [:]
        for peer in configuration.peers {
            guard let endpoint = peer.endpoint else { continue }
            do {
                resolved[peer.publicKey] = try await endpointResolver.resolve(endpoint)
            } catch {
                throw .endpointUnresolvable
            }
        }
        return resolved
    }

    private func reachableEndpoints(of configuration: TunnelConfiguration) async -> [PublicKey: ResolvedEndpoint] {
        var resolved: [PublicKey: ResolvedEndpoint] = [:]
        for peer in configuration.peers {
            guard let endpoint = peer.endpoint else { continue }
            resolved[peer.publicKey] = try? await endpointResolver.resolve(endpoint)
        }
        return resolved
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

    private static func networkPlan(
        for configuration: TunnelConfiguration,
        routedBy policy: RoutingPolicy
    ) throws(PacketTunnelError) -> TunnelNetworkPlan {
        do {
            return try TunnelNetworkPlanner.plan(for: configuration, routedBy: policy)
        } catch {
            throw .invalidNetworkPlan(error)
        }
    }
}
