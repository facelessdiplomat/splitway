public protocol ClipboardTextSource: Sendable {
    func text() async -> String?
}
