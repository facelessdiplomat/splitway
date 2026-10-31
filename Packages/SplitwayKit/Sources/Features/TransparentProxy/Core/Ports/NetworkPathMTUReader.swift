public protocol NetworkPathMTUReader: Sendable {
    func currentPathMTU() -> Int?
}
