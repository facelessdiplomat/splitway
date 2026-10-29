import TunnelConfiguration

public enum TunnelMTU: Sendable, Hashable {
    public static let wireGuardOverheadBytes = 80

    case fixed(MTU)
    case pathMTUWithOverhead(bytes: Int)
}
