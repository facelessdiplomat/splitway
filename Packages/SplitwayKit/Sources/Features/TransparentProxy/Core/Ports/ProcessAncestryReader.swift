public protocol ProcessAncestryReader: Sendable {
    func launcher(of processIdentifier: Int32) -> RunningProcess?
    func codeIdentity(of process: RunningProcess) throws(CodeIdentityReadingError) -> CodeIdentity
}
