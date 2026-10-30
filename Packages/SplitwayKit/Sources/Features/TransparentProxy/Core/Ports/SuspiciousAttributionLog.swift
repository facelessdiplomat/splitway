public protocol SuspiciousAttributionLog: Sendable {
    func recordFlow(attributedToNetworkExtensionAt executablePath: String)
}
