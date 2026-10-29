public enum QRScannerState: Sendable, Equatable {
    case preparing
    case scanning
    case cameraUnavailable
    case accessDenied
    case accessRestricted
}
