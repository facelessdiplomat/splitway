import AppRouting
import Foundation
import SharedKernel
import Synchronization
import TunnelEngine

public final class ProxiedFlowRouter: Sendable {
    private static let nameLookupTimeout = Duration.seconds(5)

    private struct ActiveRuntime: Sendable {
        let runtime: TransparentProxyRuntime
        let generation: Int
    }

    private struct State: Sendable {
        var runtime: TransparentProxyRuntime?
        var generation = 0
        var relays: [ObjectIdentifier: any FlowRelay] = [:]
    }

    private let sourceResolver: SourceApplicationResolver
    private let environment: RelayEnvironment
    private let policy: RelayPolicy
    private let state = Mutex(State())

    public init(
        sourceResolver: SourceApplicationResolver,
        environment: RelayEnvironment,
        policy: RelayPolicy = .standard
    ) {
        self.sourceResolver = sourceResolver
        self.environment = environment
        self.policy = policy
    }

    public func activate(_ runtime: TransparentProxyRuntime) {
        state.withLock { state in
            state.runtime = runtime
            state.generation += 1
        }
    }

    public func deactivate() -> TransparentProxyRuntime? {
        let (runtime, relays) = state.withLock { state -> (TransparentProxyRuntime?, [any FlowRelay]) in
            let current = (state.runtime, Array(state.relays.values))
            state.runtime = nil
            state.generation += 1
            state.relays = [:]
            return current
        }
        for relay in relays {
            relay.cancel()
        }
        return runtime
    }

    public func handleStream(_ flow: any ProxiedStreamFlow, request: ProxiedFlowRequest) -> Bool {
        guard let active = activeRuntime() else { return false }
        switch decision(for: request, transport: .tcp, in: active.runtime) {
        case .direct:
            return false
        case .block:
            flow.closeRead(with: .refused)
            flow.closeWrite(with: .refused)
            return true
        case .tunnel:
            environment.targetQueue.async {
                self.startStreamRelay(for: flow, request: request, in: active)
            }
            return true
        }
    }

    public func handleDatagrams(_ flow: any ProxiedDatagramFlow, request: ProxiedFlowRequest) -> Bool {
        guard let active = activeRuntime() else { return false }
        switch decision(for: request, transport: .udp, in: active.runtime) {
        case .direct:
            return false
        case .block:
            flow.closeRead(with: .refused)
            flow.closeWrite(with: .refused)
            return true
        case .tunnel:
            let relay = UDPFlowRelay(
                flow: flow,
                network: active.runtime.network,
                policy: policy.udp,
                environment: environment
            ) { endpoint in
                UserspaceNetworkDestination(address: endpoint.address, port: endpoint.port)
            }
            track(relay, generation: active.generation)
            return true
        }
    }

    private func activeRuntime() -> ActiveRuntime? {
        state.withLock { state in
            state.runtime.map { runtime in ActiveRuntime(runtime: runtime, generation: state.generation) }
        }
    }

    private func decision(
        for request: ProxiedFlowRequest,
        transport: FlowTransport,
        in runtime: TransparentProxyRuntime
    ) -> FlowRouteDecision {
        let flow = FlowDescriptor(
            source: sourceResolver.sourceApplication(of: request.auditToken),
            destination: .address(request.remoteEndpoint.address),
            port: request.remoteEndpoint.port.value,
            transport: transport
        )
        return runtime.decider.decision(for: flow, tunnel: runtime.readiness)
    }

    private func startStreamRelay(
        for flow: any ProxiedStreamFlow,
        request: ProxiedFlowRequest,
        in active: ActiveRuntime
    ) {
        let relay = TCPFlowRelay(
            flow: flow,
            destination: UserspaceNetworkDestination(
                address: tunnelAddress(for: request, in: active.runtime),
                port: request.remoteEndpoint.port
            ),
            network: active.runtime.network,
            policy: policy.tcp,
            environment: environment
        )
        track(relay, generation: active.generation)
    }

    private func tunnelAddress(for request: ProxiedFlowRequest, in runtime: TransparentProxyRuntime) -> IPAddress {
        let address = request.remoteEndpoint.address
        guard case .hostname(let name) = runtime.names.target(forHostname: request.remoteHostname, address: address),
            let resolved = try? runtime.network.lookUpAddresses(of: name, timeout: Self.nameLookupTimeout)
        else { return address }
        return runtime.names.address(choosingFrom: resolved, insteadOf: address)
    }

    private func track(_ relay: any FlowRelay, generation: Int) {
        let identifier = ObjectIdentifier(relay)
        let isCurrent = state.withLock { state in
            guard state.generation == generation else { return false }
            state.relays[identifier] = relay
            return true
        }
        guard isCurrent else {
            relay.cancel()
            return
        }
        relay.start { [weak self] in
            self?.state.withLock { state in
                state.relays[identifier] = nil
            }
        }
    }
}
