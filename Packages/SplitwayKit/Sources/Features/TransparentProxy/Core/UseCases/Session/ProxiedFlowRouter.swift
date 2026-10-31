import AppRouting
import Foundation
import SharedKernel
import Synchronization
import TunnelEngine

public final class ProxiedFlowRouter: Sendable {
    private struct ActiveRuntime: Sendable {
        let runtime: TransparentProxyRuntime
        let decider: FlowRoutingDecider
        let readiness: TunnelReadiness
        let generation: Int
    }

    private struct State: Sendable {
        var runtime: TransparentProxyRuntime?
        var decider: FlowRoutingDecider?
        var readiness = TunnelReadiness.unavailable
        var generation = 0
        var relays: [ObjectIdentifier: any FlowRelay] = [:]
    }

    private let sourceResolver: SourceApplicationResolver
    private let attribution: SuspiciousAttributionMonitor
    private let environment: RelayEnvironment
    private let policy: RelayPolicy
    private let addresses: TunnelAddressResolver
    private let state = Mutex(State())

    public init(
        sourceResolver: SourceApplicationResolver,
        attribution: SuspiciousAttributionMonitor,
        environment: RelayEnvironment,
        policy: RelayPolicy = .standard
    ) {
        self.sourceResolver = sourceResolver
        self.attribution = attribution
        self.environment = environment
        self.policy = policy
        addresses = TunnelAddressResolver(clock: environment.clock)
    }

    public var currentRuntime: TransparentProxyRuntime? {
        state.withLock { state in state.runtime }
    }

    public func activate(_ runtime: TransparentProxyRuntime) {
        state.withLock { state in
            state.runtime = runtime
            state.decider = runtime.decider
            state.readiness = .ready(carriesIPv6: runtime.carriesIPv6)
            state.generation += 1
        }
    }

    public func replaceDecider(with decider: FlowRoutingDecider) {
        state.withLock { state in
            guard state.runtime != nil else { return }
            state.decider = decider
        }
    }

    public func updateReadiness(_ readiness: TunnelReadiness) {
        state.withLock { state in
            guard state.runtime != nil else { return }
            state.readiness = readiness
        }
    }

    public func closeIdleRelays(at moment: Date) {
        let relays = state.withLock { state in Array(state.relays.values) }
        for relay in relays {
            _ = relay.closeIfIdle(at: moment)
        }
    }

    public func deactivate() -> TransparentProxyRuntime? {
        let (runtime, relays) = state.withLock { state -> (TransparentProxyRuntime?, [any FlowRelay]) in
            let current = (state.runtime, Array(state.relays.values))
            state.runtime = nil
            state.decider = nil
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
        let target = active.runtime.plan.dnsRedirection.target(for: request.remoteEndpoint)
        switch decision(for: request, target: target, transport: .tcp, in: active) {
        case .direct:
            return false
        case .block:
            flow.closeRead(with: .refused)
            flow.closeWrite(with: .refused)
            return true
        case .tunnel:
            environment.targetQueue.async {
                self.startStreamRelay(for: flow, request: request, target: target, in: active)
            }
            return true
        }
    }

    public func handleDatagrams(_ flow: any ProxiedDatagramFlow, request: ProxiedFlowRequest) -> Bool {
        guard let active = activeRuntime() else { return false }
        let redirection = active.runtime.plan.dnsRedirection
        let target = redirection.target(for: request.remoteEndpoint)
        switch decision(for: request, target: target, transport: .udp, in: active) {
        case .direct:
            return false
        case .block:
            guard DNSQueryRedirection.isQuery(to: request.remoteEndpoint) else {
                flow.closeRead(with: .refused)
                flow.closeWrite(with: .refused)
                return true
            }
            track(
                DNSRefusalRelay(flow: flow, policy: policy.udp, environment: environment),
                generation: active.generation
            )
            return true
        case .tunnel:
            startDatagramRelay(for: flow, redirectedBy: redirection, in: active)
            return true
        }
    }

    private func startDatagramRelay(
        for flow: any ProxiedDatagramFlow,
        redirectedBy redirection: DNSQueryRedirection,
        in active: ActiveRuntime
    ) {
        let relay = UDPFlowRelay(
            flow: flow,
            network: active.runtime.network,
            policy: policy.udp,
            environment: environment,
            replyObserver: addresses.recordingAnswers(into: active.runtime.answeredNames)
        ) { endpoint in
            let destination = redirection.target(for: endpoint)
            return UserspaceNetworkDestination(address: destination.address, port: destination.port)
        }
        track(relay, generation: active.generation)
    }

    private func activeRuntime() -> ActiveRuntime? {
        state.withLock { state in
            guard let runtime = state.runtime, let decider = state.decider else { return nil }
            return ActiveRuntime(
                runtime: runtime, decider: decider, readiness: state.readiness, generation: state.generation)
        }
    }

    private func decision(
        for request: ProxiedFlowRequest,
        target: FlowEndpoint,
        transport: FlowTransport,
        in active: ActiveRuntime
    ) -> FlowRouteDecision {
        let source = sourceResolver.sourceApplication(of: request.auditToken)
        attribution.inspect(source)
        let flow = FlowDescriptor(
            source: source,
            destination: .address(target.address),
            port: target.port.value,
            transport: transport
        )
        return active.decider.decision(for: flow, tunnel: active.readiness)
    }

    private func startStreamRelay(
        for flow: any ProxiedStreamFlow,
        request: ProxiedFlowRequest,
        target: FlowEndpoint,
        in active: ActiveRuntime
    ) {
        let isRedirected = target != request.remoteEndpoint
        let relay = TCPFlowRelay(
            flow: flow,
            destination: UserspaceNetworkDestination(
                address: isRedirected ? target.address : addresses.address(for: request, in: active.runtime),
                port: target.port
            ),
            network: active.runtime.network,
            policy: policy.tcp,
            environment: environment
        )
        track(relay, generation: active.generation)
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
