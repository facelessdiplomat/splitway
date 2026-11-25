import Foundation
import Network

enum ConnectLatencyProbe {
    private static let millisecondsPerSecond = 1_000.0
    private static let attosecondsPerMillisecond = 1e15

    static func medianMilliseconds(toConnectTo host: String, attempts: Int) async -> Double? {
        var samples: [Double] = []
        for _ in 0..<attempts {
            if let sample = await milliseconds(toConnectTo: host) {
                samples.append(sample)
            }
        }
        return samples.median
    }

    private static func milliseconds(toConnectTo host: String) async -> Double? {
        let connection = NWConnection(host: NWEndpoint.Host(host), port: .https, using: .tcp)
        defer { connection.cancel() }
        let started = ContinuousClock.now
        guard await ConnectionEndpointProbe.isReady(connection) else { return nil }
        let elapsed = ContinuousClock.now - started
        return Double(elapsed.components.seconds) * millisecondsPerSecond
            + Double(elapsed.components.attoseconds) / attosecondsPerMillisecond
    }
}
