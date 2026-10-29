import Foundation
import NetworkExtension
import ProviderMessaging

public actor TunnelProviderSessionMessenger: ProviderMessenger {
    private static let replyTimeout = Duration.seconds(3)

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
                let pendingReply = PendingProviderReply(continuation)
                let timeout = Task {
                    try await Task.sleep(for: Self.replyTimeout)
                    pendingReply.resume(with: .failure(ProviderReplyTimeout()))
                }
                do {
                    try session.sendProviderMessage(message) { response in
                        timeout.cancel()
                        pendingReply.resume(with: .success(response))
                    }
                } catch {
                    timeout.cancel()
                    pendingReply.resume(with: .failure(error))
                }
            }
        } catch is ProviderReplyTimeout {
            throw .noResponse
        } catch {
            throw .extensionUnavailable
        }
        guard let reply else { throw .noResponse }
        return reply
    }
}
