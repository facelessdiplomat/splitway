import ProviderMessaging
import Testing
import TunnelConnection
import TunnelEngine

@Suite
struct FetchRuntimeStatisticsUseCaseTests {
    @Test
    func returnsTheStatisticsTheExtensionReports() async throws {
        let statistics = RuntimeStatistics(peers: [])
        let messenger = StubProviderMessenger(outcome: .success(.runtimeStatistics(statistics: statistics)))

        #expect(try await FetchRuntimeStatisticsUseCase(messenger: messenger).execute() == statistics)
    }

    @Test(arguments: [
        (
            StubProviderMessenger.Outcome.success(.failure(reason: .tunnelNotRunning)),
            RuntimeStatisticsError.tunnelNotRunning
        ),
        (.success(.failure(reason: .unsupportedProtocolVersion)), .incompatibleExtension),
        (.success(.routingPolicyApplied), .unexpectedResponse),
        (.failure(.extensionUnavailable), .extensionUnavailable),
        (.failure(.noResponse), .extensionUnavailable),
        (.failure(.incompatibleExtension(protocolVersion: 2)), .incompatibleExtension),
    ])
    func explainsWhyStatisticsAreUnavailable(outcome: StubProviderMessenger.Outcome, error: RuntimeStatisticsError)
        async
    {
        let useCase = FetchRuntimeStatisticsUseCase(messenger: StubProviderMessenger(outcome: outcome))

        await #expect(throws: error) {
            try await useCase.execute()
        }
    }
}

struct StubProviderMessenger: ProviderMessenger {
    typealias Outcome = Result<ProviderResponse, ProviderMessagingError>

    let outcome: Outcome

    func send(_ request: ProviderRequest) async throws(ProviderMessagingError) -> ProviderResponse {
        try outcome.get()
    }
}
