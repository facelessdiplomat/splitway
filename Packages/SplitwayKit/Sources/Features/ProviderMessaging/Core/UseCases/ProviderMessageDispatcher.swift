import Foundation

public struct ProviderMessageDispatcher<Handler: ProviderMessageHandler> {
    private let handler: Handler
    private let codec = ProviderMessageCodec()

    public init(handler: Handler) {
        self.handler = handler
    }

    public nonisolated(nonsending) func response(to message: Data) async -> Data {
        let response: ProviderResponse
        do {
            let request = try codec.decodeRequest(from: message)
            response = await handler.handle(request)
        } catch .unsupportedProtocolVersion {
            response = .failure(reason: .unsupportedProtocolVersion)
        } catch {
            response = .failure(reason: .malformedRequest)
        }
        return encoded(response)
    }

    private func encoded(_ response: ProviderResponse) -> Data {
        if let message = try? codec.encode(response) {
            return message
        }
        return (try? codec.encode(.failure(reason: .internalFailure))) ?? Data()
    }
}

extension ProviderMessageDispatcher: Sendable where Handler: Sendable {}
