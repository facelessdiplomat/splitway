import DNSProxy
import SharedKernel

struct TunnelAddressResolver: Sendable {
    private static let nameLookupTimeout = Duration.seconds(5)

    let clock: any WallClock

    func address(for request: ProxiedFlowRequest, in runtime: TransparentProxyRuntime) -> IPAddress {
        let address = request.remoteEndpoint.address
        guard case .hostname(let name) = runtime.names.target(forHostname: request.remoteHostname, address: address)
        else { return address }
        let now = clock.now()
        var answered = runtime.answeredNames.addresses(for: name, at: now)
        if answered.isEmpty,
            let resolved = try? runtime.network.lookUpAddresses(of: name, timeout: Self.nameLookupTimeout)
        {
            runtime.answeredNames.record(resolved, for: name, at: now)
            answered = resolved
        }
        return runtime.names.address(choosingFrom: answered, insteadOf: address)
    }

    func recordingAnswers(into names: TunnelAnsweredNames) -> @Sendable (ProxiedDatagram) -> Void {
        { [clock] reply in
            guard DNSQueryRedirection.isQuery(to: reply.remoteEndpoint),
                let answers = try? DNSAddressAnswers(parsing: Array(reply.payload))
            else { return }
            names.record(answers, at: clock.now())
        }
    }
}
