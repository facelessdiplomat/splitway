import Foundation

struct ThroughputSample: Sendable {
    private static let downloadAddress = "https://proof.ovh.net/files/100Mb.dat"
    private static let latencyHost = "proof.ovh.net"
    private static let latencyAttempts = 10
    private static let singleStreamAttempts = 3
    private static let parallelStreamCount = 2
    private static let bitsPerByte = 8.0
    private static let bitsPerMegabit = 1_000_000.0

    let connectMilliseconds: Double?
    let singleStreamMegabits: [Double]
    let parallelMegabits: Double?
    let failedDownloads: Int
    let started: Date
    let finished: Date

    func summary(labelled label: String) -> String {
        [
            label,
            "tcp-ms=\(Self.format(connectMilliseconds))",
            "single-mbps=\(singleStreamMegabits.map { value in Self.format(value) }.joined(separator: ","))",
            "single-median-mbps=\(Self.format(singleStreamMegabits.median))",
            "parallel-mbps=\(Self.format(parallelMegabits))",
            "failed=\(failedDownloads)",
            "window=\(Int(started.timeIntervalSince1970))-\(Int(finished.timeIntervalSince1970))",
        ].joined(separator: " ")
    }

    static func measure() async -> ThroughputSample {
        let started = Date()
        let connect = await ConnectLatencyProbe.medianMilliseconds(toConnectTo: latencyHost, attempts: latencyAttempts)
        var single: [DownloadOutcome] = []
        for _ in 0..<singleStreamAttempts {
            single.append(await DownloadOutcome.download(from: downloadAddress))
        }
        let parallelStarted = Date()
        let parallel = await withTaskGroup(of: DownloadOutcome.self) { group in
            for _ in 0..<parallelStreamCount {
                group.addTask { await DownloadOutcome.download(from: downloadAddress) }
            }
            return await group.reduce(into: []) { outcomes, outcome in outcomes.append(outcome) }
        }
        let parallelSeconds = Date().timeIntervalSince(parallelStarted)
        return ThroughputSample(
            connectMilliseconds: connect,
            singleStreamMegabits: single.compactMap(megabitsPerSecond),
            parallelMegabits: aggregateMegabitsPerSecond(of: parallel, in: parallelSeconds),
            failedDownloads: (single + parallel).filter { outcome in outcome.byteCount == nil }.count,
            started: started,
            finished: Date()
        )
    }

    private static func megabitsPerSecond(of outcome: DownloadOutcome) -> Double? {
        outcome.byteCount.map { bytes in megabits(of: bytes) / max(outcome.seconds, .ulpOfOne) }
    }

    private static func aggregateMegabitsPerSecond(of outcomes: [DownloadOutcome], in seconds: Double) -> Double? {
        let byteCounts = outcomes.compactMap(\.byteCount)
        guard byteCounts.count == outcomes.count else { return nil }
        return megabits(of: byteCounts.reduce(0, +)) / max(seconds, .ulpOfOne)
    }

    private static func megabits(of bytes: Int) -> Double {
        Double(bytes) * bitsPerByte / bitsPerMegabit
    }

    private static func format(_ value: Double?) -> String {
        value.map { known in String(format: "%.1f", known) } ?? "none"
    }
}
