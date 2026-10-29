import Foundation
import ProviderMessaging
import Testing

@Suite
struct ProviderMessageDispatcherTests {
    private let codec = ProviderMessageCodec()

    @Test
    func passesDecodedRequestsToTheHandlerAndEncodesItsResponse() async throws {
        let handler = RecordingProviderMessageHandler(response: .health(isTunnelRunning: true))
        let dispatcher = ProviderMessageDispatcher(handler: handler)

        let reply = await dispatcher.response(to: try codec.encode(.healthCheck))

        #expect(try codec.decodeResponse(from: reply) == .health(isTunnelRunning: true))
        #expect(await handler.receivedRequests == [.healthCheck])
    }

    @Test
    func answersAnotherProtocolVersionWithAnExplicitFailure() async throws {
        let handler = RecordingProviderMessageHandler(response: .routingPolicyApplied)
        let dispatcher = ProviderMessageDispatcher(handler: handler)

        let reply = await dispatcher.response(to: Data(#"{"protocolVersion":2,"payload":{"healthCheck":{}}}"#.utf8))

        #expect(try codec.decodeResponse(from: reply) == .failure(reason: .unsupportedProtocolVersion))
        #expect(await handler.receivedRequests.isEmpty)
    }

    @Test
    func answersCorruptedDataWithAnExplicitFailure() async throws {
        let dispatcher = ProviderMessageDispatcher(
            handler: RecordingProviderMessageHandler(response: .routingPolicyApplied))

        let reply = await dispatcher.response(to: Data([0xFF, 0x00, 0x7B]))

        #expect(try codec.decodeResponse(from: reply) == .failure(reason: .malformedRequest))
    }
}

actor RecordingProviderMessageHandler: ProviderMessageHandler {
    private(set) var receivedRequests: [ProviderRequest] = []
    private let response: ProviderResponse

    init(response: ProviderResponse) {
        self.response = response
    }

    func handle(_ request: ProviderRequest) async -> ProviderResponse {
        receivedRequests.append(request)
        return response
    }
}
