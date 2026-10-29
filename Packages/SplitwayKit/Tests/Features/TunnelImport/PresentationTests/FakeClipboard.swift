import TunnelImport

struct FakeClipboard: ClipboardTextSource {
    let contents: String?

    func text() async -> String? {
        contents
    }
}
