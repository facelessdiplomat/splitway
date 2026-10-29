#if os(macOS)
    import Darwin
    import Foundation
    import Testing
    import TransparentProxy
    import TransparentProxyInfrastructure

    @Suite
    struct SecurityCodeIdentityReaderTests {
        @Test
        func readsTheCodeIdentityOfThisProcessFromItsAuditToken() throws {
            let auditToken = try Self.auditTokenOfThisProcess()

            let identity = try SecurityCodeIdentityReader().codeIdentity(of: auditToken)

            let executablePath = try #require(Bundle.main.executableURL).resolvingSymlinksInPath().path(
                percentEncoded: false)
            #expect(auditToken.processInstance.identifier == getpid())
            #expect(identity.executablePath == executablePath)
            #expect(identity.signingIdentifier != nil)
        }

        @Test
        func reportsAProcessThatDoesNotExist() throws {
            let missingProcess = try AuditToken(
                bytes: [UInt8](repeating: 0, count: 20) + [0xFF, 0xFF, 0xFF, 0x7F] + [UInt8](repeating: 0, count: 8))

            #expect(throws: CodeIdentityReadingError.processUnavailable) {
                try SecurityCodeIdentityReader().codeIdentity(of: missingProcess)
            }
        }

        private static func auditTokenOfThisProcess() throws -> AuditToken {
            var token = audit_token_t()
            var wordCount = mach_msg_type_number_t(MemoryLayout<audit_token_t>.size / MemoryLayout<natural_t>.size)
            let result = withUnsafeMutablePointer(to: &token) { pointer in
                pointer.withMemoryRebound(to: integer_t.self, capacity: Int(wordCount)) { words in
                    task_info(mach_task_self_, task_flavor_t(TASK_AUDIT_TOKEN), words, &wordCount)
                }
            }
            try #require(result == KERN_SUCCESS)
            return try AuditToken(bytes: withUnsafeBytes(of: token) { tokenBytes in Array(tokenBytes) })
        }
    }
#endif
