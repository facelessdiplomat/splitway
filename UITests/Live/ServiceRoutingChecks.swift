struct ServiceRoutingChecks: Sendable {
    static let directHosts = ["icanhazip.com", "nbg1-speed.hetzner.com"]

    let selectedHostKinds: [String: ResolvedAddressKinds]
    let selectedConnections: [String: String]
    let directConnections: [String: String]
    let otherHostAnswersAreFake: Bool
    let traceHostsOutsideTheTunnel: [String]

    var selectedHostsNotOnlyFake: [String] {
        selectedHostKinds.filter { _, kinds in !kinds.isOnlyFake }.keys.sorted()
    }

    var connectionsOutsideFakeAddresses: [String] {
        selectedConnections.filter { _, kind in kind != "fake-ipv4" }.map { host, kind in "\(host) \(kind)" }.sorted()
    }

    var summary: String {
        let kinds = selectedHostKinds.keys.sorted().map { host in "\(host) \(selectedHostKinds[host]?.summary ?? "")" }
        let direct = directConnections.map { host, kind in "\(host) \(kind)" }.sorted()
        return "selected-not-only-fake=\(selectedHostsNotOnlyFake)"
            + " selected-connections-not-fake=\(connectionsOutsideFakeAddresses)"
            + " direct-connections=\(direct) other-answers-fake=\(otherHostAnswersAreFake)"
            + " trace-outside-tunnel=\(traceHostsOutsideTheTunnel) selected-answers=\(kinds)"
    }

    static func measure(
        selectedHosts: [String],
        otherHost: String,
        traceHosts: [String],
        tunnel: ServicePathSnapshot,
        direct: ServicePathSnapshot
    ) async -> ServiceRoutingChecks {
        let resolution = await Task.detached {
            (
                Dictionary(
                    uniqueKeysWithValues: selectedHosts.map { host in
                        (host, ServiceRoutingProbe.addressKinds(of: host))
                    }
                ),
                ServiceRoutingProbe.addressKinds(of: otherHost).hasAnyFake
            )
        }.value
        return ServiceRoutingChecks(
            selectedHostKinds: resolution.0,
            selectedConnections: await connectionKinds(of: selectedHosts),
            directConnections: await connectionKinds(of: directHosts),
            otherHostAnswersAreFake: resolution.1,
            traceHostsOutsideTheTunnel: await traceOutcomes(of: traceHosts, tunnel: tunnel, direct: direct)
        )
    }

    private static func connectionKinds(of hosts: [String]) async -> [String: String] {
        var kinds: [String: String] = [:]
        for host in hosts {
            kinds[host] = await ConnectionEndpointProbe.endpointKind(of: host)
        }
        return kinds
    }

    private static func traceOutcomes(
        of hosts: [String],
        tunnel: ServicePathSnapshot,
        direct: ServicePathSnapshot
    ) async -> [String] {
        var outsideTheTunnel: [String] = []
        for host in hosts {
            let outcome = await ServiceRoutingProbe.traceOutcome(
                of: host,
                tunnelAddress: tunnel.selectedAddress,
                directAddresses: [direct.selectedAddress, direct.otherAddress]
            )
            if outcome != "tunnel" {
                outsideTheTunnel.append("\(host) \(outcome)")
            }
        }
        return outsideTheTunnel
    }
}
