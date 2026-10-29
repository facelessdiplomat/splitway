import SharedKernel

public struct Endpoint: Sendable, Hashable {
    public let host: EndpointHost
    public let port: NetworkPort

    public init(host: EndpointHost, port: NetworkPort) {
        self.host = host
        self.port = port
    }

    public init(_ text: String) throws(EndpointParsingError) {
        self = try EndpointParser.parse(text)
    }
}
