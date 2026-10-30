public enum SecretDeliveryReply: Sendable, Equatable {
    case done
    case failed(SecretDeliveryFailure)

    public func requireSuccess() throws(SecretDeliveryError) {
        if case .failed(let failure) = self {
            throw .rejected(failure)
        }
    }
}
