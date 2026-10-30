import Foundation
import Network
@preconcurrency import NetworkExtension
import Synchronization

final class DNSDatagramForwarder: Sendable {
    private static let replyTimeout = DispatchTimeInterval.seconds(10)

    private let flow: Mutex<NEAppProxyUDPFlow>
    private let queue: DispatchQueue

    init(_ flow: sending NEAppProxyUDPFlow, queue: DispatchQueue) {
        self.flow = Mutex(flow)
        self.queue = queue
    }

    func start() {
        flow.withLock { flow in
            flow.open(withLocalFlowEndpoint: nil) { error in
                guard error == nil else { return }
                self.queue.async { self.readNext() }
            }
        }
    }

    private func readNext() {
        flow.withLock { flow in
            flow.readDatagrams { datagrams, error in
                guard error == nil, let datagrams, !datagrams.isEmpty else {
                    self.queue.async { self.close() }
                    return
                }
                self.queue.async {
                    for (payload, endpoint) in datagrams {
                        self.forward(payload, to: endpoint)
                    }
                    self.readNext()
                }
            }
        }
    }

    private func forward(_ payload: Data, to endpoint: Network.NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: .udp)
        connection.start(queue: queue)
        connection.send(content: payload, completion: .contentProcessed { _ in })
        connection.receiveMessage { reply, _, _, _ in
            connection.cancel()
            guard let reply else { return }
            self.queue.async { self.write(reply, from: endpoint) }
        }
        queue.asyncAfter(deadline: .now() + Self.replyTimeout) { connection.cancel() }
    }

    private func write(_ reply: Data, from endpoint: Network.NWEndpoint) {
        flow.withLock { flow in
            flow.writeDatagrams([(reply, endpoint)]) { _ in }
        }
    }

    private func close() {
        flow.withLock { flow in
            flow.closeReadWithError(nil)
            flow.closeWriteWithError(nil)
        }
    }
}
