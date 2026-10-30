import Foundation

struct AddressProbe {
    private static let echoAddress = "https://api.ipify.org"
    private static let timeout: TimeInterval = 10
    private static let successStatus = 200

    func run() async -> ProbeLine {
        let clock = ContinuousClock()
        let start = clock.now
        let outcome = await fetchAddress()
        return ProbeLine(check: "address", outcome: outcome.outcome, detail: outcome.detail, elapsed: clock.now - start)
    }

    private func fetchAddress() async -> (outcome: String, detail: String) {
        guard let address = URL(string: Self.echoAddress) else { return ("failed", "invalid-address") }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = Self.timeout
        configuration.timeoutIntervalForResource = Self.timeout
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        do {
            let (data, response) = try await session.data(from: address)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard status == Self.successStatus else { return ("failed", "http-\(status)") }
            guard let text = String(bytes: data, encoding: .utf8) else { return ("failed", "not-text") }
            return ("ok", text.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch let error as URLError {
            return ("failed", "url-error-\(error.code.rawValue)")
        } catch {
            return ("failed", "error")
        }
    }
}
