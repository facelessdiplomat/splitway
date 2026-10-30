import Dispatch
import Foundation
import SharedKernel
import SharedKernelTestSupport
import TransparentProxy
import TunnelEngine
import TunnelEngineTestSupport

enum RelayFixtures {
    static let start = Date(timeIntervalSinceReferenceDate: 815_000_000)
    static let targetQueue = DispatchQueue(label: "Splitway.Tests.Relays", attributes: .concurrent)

    static func environment(clock: any WallClock = FixedWallClock(start)) -> RelayEnvironment {
        RelayEnvironment(targetQueue: targetQueue, clock: clock)
    }

    static func endpoint(_ lastOctet: UInt32, port: Int = 443) throws -> FlowEndpoint {
        FlowEndpoint(address: .ipv4(0xCB00_7100 | lastOctet), port: try NetworkPort(port))
    }

    static func destination(of endpoint: FlowEndpoint) -> UserspaceNetworkDestination {
        UserspaceNetworkDestination(address: endpoint.address, port: endpoint.port)
    }

    static func connection(_ index: Int, of network: InMemoryUserspaceNetwork) async -> InMemoryUserspaceConnection {
        await network.state.wait { snapshot in snapshot.connections.count > index }
        return network.state.current.connections[index]
    }
}

final class FinishSignal: Sendable {
    let state = AwaitableState(false)

    func callAsFunction() {
        state.update { isFinished in isFinished = true }
    }

    func wait() async {
        await state.wait { isFinished in isFinished }
    }
}
