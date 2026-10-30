extension SecretDeliveryMessage: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        switch self {
        case .store(let tunnel, _): "SecretDeliveryMessage.store(\(tunnel.rawValue), redacted)"
        case .remove(let tunnel): "SecretDeliveryMessage.remove(\(tunnel.rawValue))"
        }
    }

    public var debugDescription: String {
        description
    }

    public var customMirror: Mirror {
        Mirror(self, children: [])
    }
}
