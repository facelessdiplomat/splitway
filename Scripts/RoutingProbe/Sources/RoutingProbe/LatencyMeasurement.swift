import Foundation
import RoutingProbeCore

struct LatencyMeasurement {
    private static let timeout: TimeInterval = 15

    let address: URL
    let attempts: Int

    func run() async -> [String] {
        var lines: [String] = []
        var samples: [TransactionTimes] = []
        for attempt in 1...attempts {
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
        MeasurementLine(
            "latency \(attempt)",
            fields: [
                ("dns-ms", MeasurementLine.milliseconds(times.domainLookup)),
                ("tcp-ms", MeasurementLine.milliseconds(times.connection)),
                ("tls-ms", MeasurementLine.milliseconds(times.secureConnection)),
                ("first-byte-ms", MeasurementLine.milliseconds(times.firstByte)),
                ("protocol", times.networkProtocol),
            ]
        ).text
    }

    private static func summary(of samples: [TransactionTimes]) -> String {
        let median = { (values: [TimeInterval?]) in MeasurementLine.milliseconds(values.compactMap(\.self).median) }
        return MeasurementLine(
            "latency median",
            fields: [
                ("dns-ms", median(samples.map(\.domainLookup))),
                ("tcp-ms", median(samples.map(\.connection))),
                ("tls-ms", median(samples.map(\.secureConnection))),
                ("first-byte-ms", median(samples.map(\.firstByte))),
            ]
        ).text
    }
}
