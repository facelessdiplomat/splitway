public struct FlowDescriptor: Sendable, Hashable {
    public let source: SourceApplication
    public let destination: FlowDestination
    public let port: UInt16
    public let transport: FlowTransport

    public init(source: SourceApplication, destination: FlowDestination, port: UInt16, transport: FlowTransport) {
        self.source = source
        self.destination = destination
        self.port = port
        self.transport = transport
    }
}
