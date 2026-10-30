import Foundation

@objc protocol SecretsSpikeService {
    func describeProcess(reply: @escaping @Sendable (String) -> Void)
    func storeInSystemKeychain(_ secret: Data, reply: @escaping @Sendable (String) -> Void)
    func loadFromSystemKeychain(reply: @escaping @Sendable (Data?, String) -> Void)
}
