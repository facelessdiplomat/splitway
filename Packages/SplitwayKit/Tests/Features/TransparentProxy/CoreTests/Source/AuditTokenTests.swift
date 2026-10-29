import Testing
import TransparentProxy

@Suite
struct AuditTokenTests {
    private static let tokenBytes: [UInt8] = [
        0xF5, 0x01, 0x00, 0x00, 0xF5, 0x01, 0x00, 0x00, 0x14, 0x00, 0x00, 0x00, 0xF5, 0x01, 0x00, 0x00,
        0x14, 0x00, 0x00, 0x00, 0x92, 0x10, 0x00, 0x00, 0xA8, 0x86, 0x01, 0x00, 0x07, 0x00, 0x00, 0x00,
    ]

    @Test
    func readsTheProcessIdentifierAndVersionFromTheTokenBytes() throws {
        let auditToken = try AuditToken(bytes: Self.tokenBytes)

        #expect(auditToken.processInstance == ProcessInstance(identifier: 4242, version: 7))
        #expect(auditToken.bytes == Self.tokenBytes)
    }

    @Test(arguments: [31, 33])
    func rejectsATokenOfAnotherSize(byteCount: Int) {
        #expect(throws: AuditTokenError.wrongByteCount) {
            try AuditToken(bytes: [UInt8](repeating: 0, count: byteCount))
        }
    }
}
