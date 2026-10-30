import Diagnostics
import Foundation
import Network
@preconcurrency import NetworkExtension
import Synchronization

final class DNSDatagramForwarder: Sendable {
    private static let replyTimeout = DispatchTimeInterval.seconds(10)

    private let flow: Mutex<NEAppProxyUDPFlow>
    private let queue: DispatchQueue
    private let log: LogRecorder

    init(_ flow: sending NEAppProxyUDPFlow, queue: DispatchQueue, log: LogRecorder) {
        self.flow = Mutex(flow)
        self.queue = queue
        self.log = log
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
        connection.send(
            content: payload,
            completion: .contentProcessed { error in
                self.log.record(.info, "SP-9 forward sent to \(endpoint) error=\(String(describing: error))")
            })
        connection.receiveMessage { reply, _, _, error in
            connection.cancel()
            self.log.record(
                .info,
                "SP-9 forward reply from \(endpoint) bytes=\(reply?.count ?? -1) error=\(String(describing: error))")
            guard let reply else { return }
            self.queue.async { self.write(reply, from: endpoint) }
        }
        queue.asyncAfter(deadline: .now() + Self.replyTimeout) { connection.cancel() }
    }

    private func write(_ reply: Data, from endpoint: Network.NWEndpoint) {
        flow.withLock { flow in
            flow.writeDatagrams([(reply, endpoint)]) { error in
                self.log.record(.info, "SP-9 forward wrote reply error=\(String(describing: error))")
            }
        }
    }

    private func close() {
        flow.withLock { flow in
            flow.closeReadWithError(nil)
            flow.closeWriteWithError(nil)
        }
    }
}
