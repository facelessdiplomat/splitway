import Foundation

public enum ProbeRequest: Equatable, Sendable {
    case routing
    case download(URL, attempts: Int)
    case upload(URL, attempts: Int, byteCount: Int)
    case latency(URL, attempts: Int)
    case backgroundStart(URL, delaySeconds: Int)
    case backgroundCollect(timeoutSeconds: Int)

    private static let defaultTransferAttempts = 3
    private static let defaultLatencyAttempts = 10
    private static let defaultUploadByteCount = 25_000_000
    private static let defaultBackgroundDelaySeconds = 5
    private static let defaultCollectionTimeoutSeconds = 30
    private static let webSchemes: Set<String> = ["http", "https"]

    public init(arguments: [String]) throws(ProbeRequestError) {
        guard let mode = arguments.first else {
            self = .routing
            return
        }
        let operands = Array(arguments.dropFirst())
        switch mode {
        case "download":
            self = .download(
                try Self.address(in: operands),
                attempts: try Self.count(at: 1, in: operands, otherwise: Self.defaultTransferAttempts))
        case "upload":
            self = .upload(
                try Self.address(in: operands),
                attempts: try Self.count(at: 1, in: operands, otherwise: Self.defaultTransferAttempts),
                byteCount: try Self.count(at: 2, in: operands, otherwise: Self.defaultUploadByteCount))
        case "latency":
            self = .latency(
                try Self.address(in: operands),
                attempts: try Self.count(at: 1, in: operands, otherwise: Self.defaultLatencyAttempts))
        case "background-start":
            self = .backgroundStart(
                try Self.address(in: operands),
                delaySeconds: try Self.count(at: 1, in: operands, otherwise: Self.defaultBackgroundDelaySeconds))
        case "background-collect":
            self = .backgroundCollect(
                timeoutSeconds: try Self.count(at: 0, in: operands, otherwise: Self.defaultCollectionTimeoutSeconds))
        default:
            throw .unknownMode(mode)
        }
    }

    private static func address(in operands: [String]) throws(ProbeRequestError) -> URL {
        guard let text = operands.first else { throw .missingAddress }
        guard let address = URL(string: text), let scheme = address.scheme?.lowercased(),
            webSchemes.contains(scheme), let host = address.host(), !host.isEmpty
        else { throw .invalidAddress(text) }
        return address
    }

    private static func count(at index: Int, in operands: [String], otherwise fallback: Int)
        throws(ProbeRequestError) -> Int
    {
        guard operands.indices.contains(index) else { return fallback }
        guard let count = Int(operands[index]), count > 0 else { throw .invalidCount(operands[index]) }
        return count
    }
}
