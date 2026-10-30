#if os(macOS)
    import Foundation

    @objc protocol SecretDeliveryXPCService {
        func deliver(_ request: Data, withReply reply: @escaping @Sendable (Data) -> Void)
    }
#endif
