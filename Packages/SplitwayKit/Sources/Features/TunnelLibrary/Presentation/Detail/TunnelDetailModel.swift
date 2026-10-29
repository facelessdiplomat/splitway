import Observation
import TunnelConfiguration
import TunnelConnection
import TunnelEngine
import TunnelLibrary

@MainActor
@Observable
public final class TunnelDetailModel {
    public private(set) var peers: [PeerStatisticsRow] = []
    public private(set) var statisticsProblem: RuntimeStatisticsError?

    private let configuration: TunnelConfiguration
    private let polling: TunnelStatisticsPolling

    public init(tunnel: Tunnel, polling: TunnelStatisticsPolling) {
        configuration = tunnel.configuration
        self.polling = polling
        show(nil)
    }

    public func trackStatistics(isTunnelRunning: Bool) async {
        guard isTunnelRunning else {
            show(nil)
            return
        }
        for await _ in polling.ticker.ticks() {
            await refreshStatistics()
        }
    }

    public func refreshStatistics() async {
        let outcome: Result<RuntimeStatistics, RuntimeStatisticsError>
        do {
            outcome = .success(try await polling.fetchStatistics.execute())
        } catch {
            outcome = .failure(error)
        }
        guard !Task.isCancelled else { return }
        switch outcome {
        case .success(let statistics):
            show(statistics)
        case .failure(let problem):
            show(nil, problem: problem)
        }
    }

    private func show(_ statistics: RuntimeStatistics?, problem: RuntimeStatisticsError? = nil) {
        let now = polling.clock.now()
        statisticsProblem = problem
        peers = configuration.peers.map { peer in
            let peerStatistics = statistics?.peers.first { reported in reported.publicKey == peer.publicKey }
            return PeerStatisticsRow(peer: peer, statistics: peerStatistics, now: now)
        }
    }
}
