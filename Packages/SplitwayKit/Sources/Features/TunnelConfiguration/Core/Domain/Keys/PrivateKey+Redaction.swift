extension PrivateKey: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        "PrivateKey(redacted)"
    }

    public var debugDescription: String {
        description
    }

    public var customMirror: Mirror {
        Mirror(self, children: [])
    }
}
