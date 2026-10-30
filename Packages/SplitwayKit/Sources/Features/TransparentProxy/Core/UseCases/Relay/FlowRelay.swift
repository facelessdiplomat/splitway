import Foundation

public protocol FlowRelay: AnyObject, Sendable {
    func start(onFinish: @escaping @Sendable () -> Void)
    func cancel()
    func closeIfIdle(at moment: Date) -> Bool
}
