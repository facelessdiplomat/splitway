import Foundation

struct DownloadOutcome: Sendable {
    let byteCount: Int?
    let errorCode: Int?
    let seconds: Double

    var summary: String {
        let duration = String(format: "%.1fs", seconds)
        if let byteCount {
            return "\(byteCount)-bytes-in-\(duration)"
        }
        return "error-\(errorCode ?? 0)-after-\(duration)"
    }

    static func download(from address: String) async -> DownloadOutcome {
        let started = Date()
        do {
            let byteCount = try await ServiceRoutingProbe.downloadedByteCount(from: address)
            return DownloadOutcome(byteCount: byteCount, errorCode: nil, seconds: Date().timeIntervalSince(started))
        } catch {
            return DownloadOutcome(
                byteCount: nil,
                errorCode: (error as? URLError)?.code.rawValue,
                seconds: Date().timeIntervalSince(started)
            )
        }
    }
}
