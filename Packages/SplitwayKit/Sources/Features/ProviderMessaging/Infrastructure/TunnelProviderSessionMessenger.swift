import Foundation
import NetworkExtension
import ProviderMessaging

public actor TunnelProviderSessionMessenger: ProviderMessenger {
    private let session: NETunnelProviderSession
    private let codec = ProviderMessageCodec()

    public init(session: sending NETunnelProviderSession) {
        self.session = session
    }

    public func send(_ request: ProviderRequest) async throws(ProviderMessagingError) -> ProviderResponse {
        guard let message = try? codec.encode(request) else { throw .malformedResponse }
        let reply = try await deliver(message)
        do {
            return try codec.decodeResponse(from: reply)
        } catch .unsupportedProtocolVersion(let version) {
            throw .incompatibleExtension(protocolVersion: version)
        } catch {
            throw .malformedResponse
        }
    }

    private func deliver(_ message: Data) async throws(ProviderMessagingError) -> Data {
        let reply: Data?
        do {
            reply = try await withCheckedThrowingContinuation { continuation in
                do {
                    try session.sendProviderMessage(message) { response in
                        continuation.resume(returning: response)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        } catch {
            throw .extensionUnavailable
        }
        guard let reply else { throw .noResponse }
        return reply
    }
}
