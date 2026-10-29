import SharedKernel
import TunnelConnection

public struct TunnelStatisticsPolling: Sendable {
    public static let refreshInterval = Duration.seconds(1)

    let fetchStatistics: FetchRuntimeStatisticsUseCase
    let clock: any WallClock
    let ticker: any Ticker

    public init(
        fetchStatistics: FetchRuntimeStatisticsUseCase,
        clock: any WallClock = SystemWallClock(),
        ticker: any Ticker = RepeatingTicker(interval: refreshInterval)
    ) {
        self.fetchStatistics = fetchStatistics
        self.clock = clock
        self.ticker = ticker
    }
}
