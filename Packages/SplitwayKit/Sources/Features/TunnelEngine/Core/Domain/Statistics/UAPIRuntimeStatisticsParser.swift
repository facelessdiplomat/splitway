public enum UAPIRuntimeStatisticsParser {
    private static let peerStartKey = "public_key"
    private static let errorCodeKey = "errno"
    private static let successCode = 0

    public static func parse(_ response: String) throws(UAPIResponseError) -> RuntimeStatistics {
        var finishedPeers: [PeerRuntimeStatistics] = []
        var currentPeer: PeerStatisticsAccumulator?
        for line in response.split(separator: "\n") {
            let (key, value) = try UAPIValue.keyAndValue(in: line)
            switch key {
            case peerStartKey:
                if let finishedPeer = currentPeer {
                    finishedPeers.append(finishedPeer.statistics)
                }
                currentPeer = PeerStatisticsAccumulator(publicKey: try UAPIValue.publicKey(value))
            case errorCodeKey:
                let code: Int = try UAPIValue.number(value)
                guard code == successCode else { throw .deviceError(code: code) }
            default:
                try currentPeer?.record(key: key, value: value)
            }
        }
        return RuntimeStatistics(peers: finishedPeers + (currentPeer.map { peer in [peer.statistics] } ?? []))
    }
}
