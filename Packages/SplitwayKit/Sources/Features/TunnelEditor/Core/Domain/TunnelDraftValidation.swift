import TunnelConfiguration
import TunnelLibrary

public struct TunnelDraftValidation: Sendable, Equatable {
    public let name: TunnelName?
    public let configuration: TunnelConfiguration?
    public let problems: [TunnelDraftProblem]

    public func problems(for field: TunnelDraftField) -> [TunnelDraftProblem] {
        problems.filter { problem in problem.field == field }
    }

    public func problems(for peer: PeerDraftID) -> [TunnelDraftProblem] {
        problems.filter { problem in
            if case .peer(peer, _) = problem.field { true } else { false }
        }
    }
}
