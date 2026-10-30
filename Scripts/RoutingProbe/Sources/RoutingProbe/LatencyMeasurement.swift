import Foundation

struct LatencyMeasurement {
    private static let timeout: TimeInterval = 15

    let address: URL
    let count: Int

    func run() async -> [String] {
        var lines: [String] = []
        var samples: [TransactionTimes] = []
        for attempt in 1...count {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = Self.timeout
            let session = URLSession(configuration: configuration)
            let collector = TransactionTimesCollector()
            do {
                _ = try await session.data(from: address, delegate: collector)
                if let times = collector.times {
                    samples.append(times)
                    lines.append(Self.line(attempt: attempt, times: times))
                }
            } catch {
                lines.append("latency \(attempt) failed \(error.localizedDescription)")
            }
            session.invalidateAndCancel()
        }
        return lines + [Self.summary(of: samples)]
    }

    private static func line(attempt: Int, times: TransactionTimes) -> String {
        "latency \(attempt) dns-ms=\(MeasurementFormat.milliseconds(times.domainLookup))"
            + " tcp-ms=\(MeasurementFormat.milliseconds(times.connection))"
            + " tls-ms=\(MeasurementFormat.milliseconds(times.secureConnection))"
            + " first-byte-ms=\(MeasurementFormat.milliseconds(times.firstByte))"
            + " protocol=\(times.networkProtocol)"
    }

    private static func summary(of samples: [TransactionTimes]) -> String {
        let median = { (values: [TimeInterval?]) in
            MeasurementFormat.milliseconds(MeasurementFormat.median(values.compactMap { value in value }))
        }
        return "latency median dns-ms=\(median(samples.map(\.domainLookup)))"
            + " tcp-ms=\(median(samples.map(\.connection)))"
            + " tls-ms=\(median(samples.map(\.secureConnection)))"
            + " first-byte-ms=\(median(samples.map(\.firstByte)))"
    }
}
