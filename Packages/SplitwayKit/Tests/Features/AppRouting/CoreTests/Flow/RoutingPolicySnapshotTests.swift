import AppRouting
import AppRoutingTestSupport
import Foundation
import SharedKernel
import Testing

@Suite
struct RoutingPolicySnapshotTests {
    @Test
    func survivesTheTripToTheExtension() throws {
        let snapshot = try FlowRoutingFixtures.snapshot(whenTunnelUnavailable: .bypass)

        let decoded = try JSONDecoder().decode(RoutingPolicySnapshot.self, from: JSONEncoder().encode(snapshot))

        #expect(decoded == snapshot)
    }

    @Test
    func rejectsASnapshotOfAnotherSchemaVersion() {
        let json = Data(
            #"{"schemaVersion":2,"applications":[],"tunnelNetworks":[],"whenTunnelUnavailable":"block"}"#.utf8)

        #expect(throws: DecodingError.self) { try JSONDecoder().decode(RoutingPolicySnapshot.self, from: json) }
    }

    @Test
    func takesTheSelectedApplicationsAndBehaviourOfThePolicy() throws {
        let applications = try FlowRoutingFixtures.snapshot().applications
        let policy = RoutingPolicy(
            mode: .selectedApplications(ApplicationSelection(applications)), whenTunnelUnavailable: .bypass)
        let networks = IPNetworkSet([try IPNetwork("0.0.0.0/0")])

        let snapshot = RoutingPolicySnapshot(policy: policy, tunnelNetworks: networks)

        #expect(snapshot?.applications == applications)
        #expect(snapshot?.whenTunnelUnavailable == .bypass)
        #expect(snapshot?.tunnelNetworks == networks)
        #expect(RoutingPolicySnapshot(policy: .default, tunnelNetworks: networks) == nil)
    }
}
