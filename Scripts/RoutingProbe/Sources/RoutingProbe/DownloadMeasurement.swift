import Foundation

struct DownloadMeasurement {
    private static let timeout: TimeInterval = 300
    private static let bitsPerByte = 8.0
    private static let bitsPerMegabit = 1_000_000.0

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
        return lines + ["download median-mbps=\(median)"]
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
            let (data, _) = try await session.data(from: address, delegate: collector)
            let elapsed = clock.now - start
            let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
            let rate = Double(data.count) * Self.bitsPerByte / seconds / Self.bitsPerMegabit
            let times = collector.times
            let line =
                "download \(attempt) bytes=\(data.count) seconds=\(String(format: "%.2f", seconds))"
                + " mbps=\(String(format: "%.1f", rate))"
                + " first-byte-ms=\(MeasurementFormat.milliseconds(times?.firstByte))"
            return (line, rate)
        } catch {
            return ("download \(attempt) failed \(error.localizedDescription)", nil)
        }
    }
}
