import Foundation

public protocol ProxiedStreamFlow: Sendable {
    func open(completion: @escaping @Sendable (ProxiedFlowError?) -> Void)
    func read(completion: @escaping @Sendable (Result<Data, ProxiedFlowError>) -> Void)
    func write(_ data: Data, completion: @escaping @Sendable (ProxiedFlowError?) -> Void)
    func closeRead(with error: ProxiedFlowError?)
    func closeWrite(with error: ProxiedFlowError?)
}
