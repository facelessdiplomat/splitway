import TunnelConfiguration

public enum ProxyInterfaceMTU {
    private static let wireGuardOverheadByteCount = 80
    private static let standardWireGuardMTU = 1_420
    private static let minimumForIPv6 = 1_280

    public static func mtu(configured: MTU?, pathMTU: Int?, carriesIPv6: Bool) throws(TransparentProxyError) -> MTU {
        if let configured {
            return configured
        }
        let lowest = carriesIPv6 ? minimumForIPv6 : MTU.supportedRange.lowerBound
        let fitting = pathMTU.map { pathMTU in min(pathMTU - wireGuardOverheadByteCount, standardWireGuardMTU) }
        do {
            return try MTU(max(fitting ?? standardWireGuardMTU, lowest))
        } catch {
            throw .invalidInterface
        }
    }
}
