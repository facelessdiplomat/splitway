public enum SecretDeliveryError: Error, Sendable, Equatable {
    case extensionUnreachable
    case secretUnavailable
    case rejected(SecretDeliveryFailure)
}
