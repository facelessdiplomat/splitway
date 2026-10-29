struct ApplicationPathRule: Sendable {
    private static let pathSeparator = UInt8(ascii: "/")

    let path: String
    let teamIdentifier: String?

    func covers(_ executablePath: String) -> Bool {
        let candidate = executablePath.utf8
        guard candidate.starts(with: path.utf8) else { return false }
        let remainder = candidate.dropFirst(path.utf8.count)
        return remainder.first.map { byte in byte == Self.pathSeparator } ?? true
    }
}
