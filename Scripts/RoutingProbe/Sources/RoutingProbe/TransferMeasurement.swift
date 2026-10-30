import Foundation

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
    private static let bitsPerByte = 8.0
    private static let bitsPerMegabit = 1_000_000.0

    let direction: Direction
    let address: URL
    let count: Int

    func run() async -> [String] {
        var lines: [String] = []
        var rates: [Double] = []
        for attempt in 1...count {
            let (line, rate) = await measure(attempt: attempt)
            lines.append(line)
            rate.map { rate in rates.append(rate) }
        }
        let median = MeasurementFormat.median(rates).map { rate in String(format: "%.1f", rate) } ?? "none"
        return lines + ["\(direction.name) median-mbps=\(median)"]
    }

    private func measure(attempt: Int) async -> (String, Double?) {
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
            let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
            let rate = Double(byteCount) * Self.bitsPerByte / seconds / Self.bitsPerMegabit
            let line =
                "\(direction.name) \(attempt) bytes=\(byteCount) seconds=\(String(format: "%.2f", seconds))"
                + " mbps=\(String(format: "%.1f", rate)) status=\(status)"
                + " first-byte-ms=\(MeasurementFormat.milliseconds(collector.times?.firstByte))"
            return (line, rate)
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
        (response as? HTTPURLResponse)?.statusCode ?? 0
    }
}
