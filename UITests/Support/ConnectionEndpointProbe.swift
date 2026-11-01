import Foundation
import Network

enum ConnectionEndpointProbe {
    private static let connectionTimeout: TimeInterval = 10
    private static let fakeIPv4FirstOctet: UInt8 = 198
    private static let fakeIPv4SecondOctets: ClosedRange<UInt8> = 18...19

    static func endpointKind(of host: String) async -> String {
        let connection = NWConnection(host: NWEndpoint.Host(host), port: .https, using: .tcp)
        defer { connection.cancel() }
        guard await isReady(connection), case .hostPort(let address, _) = connection.currentPath?.remoteEndpoint else {
            return "no-connection"
        }
        switch address {
        case .ipv4(let ipv4):
            return isFake(ipv4) ? "fake-ipv4" : "real-ipv4"
        case .ipv6:
            return "ipv6"
        default:
            return "other"
        }
    }

    private static func isFake(_ address: IPv4Address) -> Bool {
        let bytes = [UInt8](address.rawValue)
        return bytes.first == fakeIPv4FirstOctet && bytes.dropFirst().first.map(fakeIPv4SecondOctets.contains) == true
    }

    private static func isReady(_ connection: NWConnection) async -> Bool {
        await withCheckedContinuation { continuation in
            let outcome = OneTimeOutcome(continuation)
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready: outcome.resolve(true)
                case .failed, .cancelled: outcome.resolve(false)
                default: break
                }
            }
            connection.start(queue: .global())
            DispatchQueue.global().asyncAfter(deadline: .now() + connectionTimeout) { outcome.resolve(false) }
        }
    }
}
