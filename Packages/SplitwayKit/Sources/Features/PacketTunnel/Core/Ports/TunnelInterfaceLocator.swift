public protocol TunnelInterfaceLocator: Sendable {
    func tunnelFileDescriptor() -> Int32?
}
