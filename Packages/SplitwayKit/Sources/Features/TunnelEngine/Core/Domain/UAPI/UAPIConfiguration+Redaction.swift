extension UAPIConfiguration: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        "UAPIConfiguration(redacted)"
    }

    public var debugDescription: String {
        description
    }

    public var customMirror: Mirror {
        Mirror(self, children: [])
    }
}
