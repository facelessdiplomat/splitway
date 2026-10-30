struct ProbeFailure: Error {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    init(errno code: Int32) {
        text = SocketErrorName.name(of: code)
    }
}
