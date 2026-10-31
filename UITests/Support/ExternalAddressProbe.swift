import XCTest

@MainActor
enum ExternalAddressProbe {
    enum Failure: Error {
        case notAnAddress
    }

    private static let addressService = "https://api.ipify.org"
    private static let addressPattern = /^[0-9]{1,3}(\.[0-9]{1,3}){3}$|^[0-9a-fA-F:]+:[0-9a-fA-F:]+$/
    private static let requestTimeout: TimeInterval = 15

    static func currentAddress() async throws -> String {
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        var request = URLRequest(url: try XCTUnwrap(URL(string: addressService)))
        request.timeoutInterval = requestTimeout
        let (data, _) = try await session.data(for: request)
        let text = String(bytes: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard text.wholeMatch(of: addressPattern) != nil else { throw Failure.notAnAddress }
        return text
    }
}
