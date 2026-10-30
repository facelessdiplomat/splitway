import AppRouting
import PacketTunnel
import SharedKernel
import TunnelConfiguration
import TunnelEngine

public struct TransparentProxyStarter: Sendable {
    private static let standardWireGuardMTU = 1_420

    private let engine: any UserspaceNetworkEngine
    private let endpointResolution: ResolveTunnelEndpointsUseCase

    public init(engine: any UserspaceNetworkEngine, endpointResolution: ResolveTunnelEndpointsUseCase) {
        self.engine = engine
        self.endpointResolution = endpointResolution
    }

    public func start(_ tunnel: ActiveTunnel) async throws(TransparentProxyError) -> TransparentProxyRuntime {
        guard tunnel.routingPolicy.mode.kind == .selectedApplications else { throw .routingModeUnsupported }
        let configuration = tunnel.configuration
        let endpoints: [PublicKey: ResolvedEndpoint]
        do {
            endpoints = try await endpointResolution.allEndpoints(of: configuration)
        } catch {
            throw .endpointUnresolvable
        }
        let plan = TransparentProxyNetworkPlan(
            for: configuration,
            resolvedEndpointAddresses: endpoints.values.map(\.address)
        )
        let decider = try Self.decider(for: tunnel.routingPolicy, plan: plan)
        let network = try startNetwork(for: configuration, endpoints: endpoints)
        return TransparentProxyRuntime(
            network: network,
            configuration: configuration,
            plan: plan,
            decider: decider,
            names: HostnameResolutionPolicy(
                tunnelNetworks: plan.includedNetworks,
                resolvesNamesThroughTunnel: !configuration.interface.dns.servers.isEmpty
            ),
            readiness: .ready(
                carriesIPv6: configuration.interface.addresses.contains { network in
                    network.address.family == .ipv6
                })
        )
    }

    public static func decider(
        for policy: RoutingPolicy,
        plan: TransparentProxyNetworkPlan
    ) throws(TransparentProxyError) -> FlowRoutingDecider {
        guard policy.mode.kind == .selectedApplications,
            let snapshot = RoutingPolicySnapshot(policy: policy, tunnelNetworks: plan.includedNetworks)
        else { throw .routingModeUnsupported }
        return FlowRoutingDecider(snapshot: snapshot)
    }

    public func stop(_ runtime: TransparentProxyRuntime) {
        runtime.network.stop()
    }

    public func refreshEndpoints(of runtime: TransparentProxyRuntime) async {
        let endpoints = await endpointResolution.reachableEndpoints(of: runtime.configuration)
        let configuration = runtime.configuration
        if let update = UAPIConfigurationEncoder.endpointUpdate(for: configuration, resolvedEndpoints: endpoints) {
            try? runtime.network.apply(update)
        }
        try? runtime.network.bumpSockets()
    }

    private func startNetwork(
        for configuration: TunnelConfiguration,
        endpoints: [PublicKey: ResolvedEndpoint]
    ) throws(TransparentProxyError) -> any RunningUserspaceNetwork {
        let interface = UserspaceNetworkInterface(
            addresses: configuration.interface.addresses.map(\.address),
            dnsServers: configuration.interface.dns.servers,
            mtu: try Self.mtu(of: configuration)
        )
        do {
            return try engine.startNetwork(
                configuration: UAPIConfigurationEncoder.encode(configuration, resolvedEndpoints: endpoints),
                interface: interface
            )
        } catch {
            throw .engineFailed(error)
        }
    }

    private static func mtu(of configuration: TunnelConfiguration) throws(TransparentProxyError) -> MTU {
        if let mtu = configuration.interface.mtu {
            return mtu
        }
        do {
            return try MTU(standardWireGuardMTU)
        } catch {
            throw .invalidInterface
        }
    }
}
