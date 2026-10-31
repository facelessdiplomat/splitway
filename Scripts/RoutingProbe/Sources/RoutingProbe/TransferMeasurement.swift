import Foundation
import RoutingProbeCore

struct TransferMeasurement {
    enum Direction {
        case download
        case upload(byteCount: Int)

        var name: String {
            switch self {
            case .download: "download"
            case .upload: "upload"
            }
        }
    }

    private static let timeout: TimeInterval = 300
    private static let unknownStatus = 0

    let direction: Direction
    let address: URL
    let attempts: Int

    func run() async -> [String] {
        var lines: [String] = []
        var rates: [Double] = []
        for attempt in 1...attempts {
            let (line, rate) = await measure(attempt: attempt)
            lines.append(line)
            rate.map { rate in rates.append(rate.megabitsPerSecond) }
        }
        let median = rates.median.map { rate in String(format: "%.1f", rate) } ?? "none"
        return lines + [MeasurementLine("\(direction.name) median", fields: [("mbps", median)]).text]
    }

    private func measure(attempt: Int) async -> (String, TransferRate?) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = Self.timeout
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let collector = TransactionTimesCollector()
        let clock = ContinuousClock()
        let start = clock.now
        do {
            let (byteCount, status) = try await transfer(in: session, reportingTo: collector)
            let elapsed = clock.now - start
            let rate = TransferRate(byteCount: byteCount, duration: elapsed)
            let line = MeasurementLine(
                "\(direction.name) \(attempt)",
                fields: [
                    ("bytes", "\(byteCount)"),
                    ("seconds", MeasurementLine.seconds(elapsed)),
                    ("mbps", MeasurementLine.megabitsPerSecond(rate)),
                    ("status", "\(status)"),
                    ("first-byte-ms", MeasurementLine.milliseconds(collector.times?.firstByte)),
                ])
            return (line.text, rate)
        } catch {
            return ("\(direction.name) \(attempt) failed \(error.localizedDescription)", nil)
        }
    }

    private func transfer(in session: URLSession, reportingTo collector: TransactionTimesCollector) async throws
        -> (byteCount: Int, status: Int)
    {
        switch direction {
        case .download:
            let (data, response) = try await session.data(from: address, delegate: collector)
            return (data.count, Self.status(of: response))
        case .upload(let byteCount):
            var request = URLRequest(url: address)
            request.httpMethod = "POST"
            let (_, response) = try await session.upload(
                for: request, from: Data(count: byteCount), delegate: collector)
            return (byteCount, Self.status(of: response))
        }
    }

    private static func status(of response: URLResponse) -> Int {
        (response as? HTTPURLResponse)?.statusCode ?? unknownStatus
    }
}
