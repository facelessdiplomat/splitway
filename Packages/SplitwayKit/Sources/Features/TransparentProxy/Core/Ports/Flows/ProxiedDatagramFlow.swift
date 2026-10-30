public protocol ProxiedDatagramFlow: Sendable {
    func open(completion: @escaping @Sendable (ProxiedFlowError?) -> Void)
    func readDatagrams(completion: @escaping @Sendable (Result<[ProxiedDatagram], ProxiedFlowError>) -> Void)
    func writeDatagrams(_ datagrams: [ProxiedDatagram], completion: @escaping @Sendable (ProxiedFlowError?) -> Void)
    func closeRead(with error: ProxiedFlowError?)
    func closeWrite(with error: ProxiedFlowError?)
}
