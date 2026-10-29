public protocol CodeIdentityReader: Sendable {
    func codeIdentity(of auditToken: AuditToken) throws(CodeIdentityReadingError) -> CodeIdentity
}
