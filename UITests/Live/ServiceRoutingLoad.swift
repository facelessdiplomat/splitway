import Foundation

struct ServiceRoutingLoad: Sendable {
    static let tunnelAddress = "https://proof.ovh.net/files/1Gb.dat"
    private static let tunnelStreamCount = 2
    private static let bitsPerByte = 8.0
    private static let bitsPerMegabit = 1_000_000.0

    let tunnelOutcomes: [DownloadOutcome]
    let seconds: Double

    var tunnelCompleted: Bool {
        tunnelOutcomes.allSatisfy { outcome in outcome.byteCount != nil }
    }

    var summary: String {
        let tunnelBytes = tunnelOutcomes.compactMap(\.byteCount).reduce(0, +)
        let megabits = Double(tunnelBytes) * Self.bitsPerByte / Self.bitsPerMegabit
        return "load-tunnel=\(tunnelOutcomes.map(\.summary)) load-seconds=\(String(format: "%.1f", seconds))"
            + " load-tunnel-mbps=\(String(format: "%.0f", megabits / max(seconds, .ulpOfOne)))"
    }

    static func measure() async -> ServiceRoutingLoad {
        let started = Date()
        let tunnel = await withTaskGroup(of: DownloadOutcome.self) { group in
            for _ in 0..<tunnelStreamCount {
                group.addTask { await DownloadOutcome.download(from: tunnelAddress) }
            }
            return await group.reduce(into: []) { outcomes, outcome in outcomes.append(outcome) }
        }
        let seconds = Date().timeIntervalSince(started)
        return ServiceRoutingLoad(tunnelOutcomes: tunnel, seconds: seconds)
    }
}
