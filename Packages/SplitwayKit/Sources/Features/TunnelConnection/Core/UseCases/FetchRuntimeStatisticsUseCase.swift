import ProviderMessaging
import TunnelEngine

public struct FetchRuntimeStatisticsUseCase: Sendable {
    private let messenger: any ProviderMessenger

    public init(messenger: any ProviderMessenger) {
        self.messenger = messenger
    }

    public func execute() async throws(RuntimeStatisticsError) -> RuntimeStatistics {
        let response: ProviderResponse
        do {
            response = try await messenger.send(.runtimeStatistics)
        } catch .incompatibleExtension {
            throw .incompatibleExtension
        } catch {
            throw .extensionUnavailable
        }
        switch response {
        case .runtimeStatistics(let statistics): return statistics
        case .failure(reason: .tunnelNotRunning): throw .tunnelNotRunning
        case .failure(reason: .unsupportedProtocolVersion): throw .incompatibleExtension
        default: throw .unexpectedResponse
        }
    }
}
