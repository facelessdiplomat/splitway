extension PresharedKey: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        "PresharedKey(redacted)"
    }

    public var debugDescription: String {
        description
    }

    public var customMirror: Mirror {
        Mirror(self, children: [])
    }
}
