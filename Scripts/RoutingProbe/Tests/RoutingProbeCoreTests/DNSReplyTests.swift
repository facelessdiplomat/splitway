import RoutingProbeCore
import Testing

@Suite
struct DNSReplyTests {
    private static let question: [UInt8] =
        [6] + Array("whoami".utf8) + [6] + Array("akamai".utf8) + [3] + Array("net".utf8) + [0, 0, 1, 0, 1]

    @Test
    func readsARefusal() throws {
        let reply = try DNSReply(parsing: [0x12, 0x34, 0x81, 0x05, 0, 1, 0, 0, 0, 0, 0, 0] + Self.question)

        #expect(reply.identifier == 0x1234)
        #expect(reply.responseCode == .refused)
        #expect(reply.addresses.isEmpty)
    }

    @Test
    func readsTheAddressesOfTheAnswers() throws {
        let canonicalName: [UInt8] = [0xC0, 0x0C, 0, 5, 0, 1, 0, 0, 0, 60, 0, 2, 0xC0, 0x0C]
        let firstAddress: [UInt8] = [0xC0, 0x0C, 0, 1, 0, 1, 0, 0, 0, 60, 0, 4, 198, 51, 100, 7]
        let secondAddress: [UInt8] = [0xC0, 0x0C, 0, 1, 0, 1, 0, 0, 0, 60, 0, 4, 203, 0, 113, 9]
        let bytes =
            [0x12, 0x34, 0x81, 0x80, 0, 1, 0, 3, 0, 0, 0, 0] + Self.question
            + canonicalName + firstAddress + secondAddress

        let reply = try DNSReply(parsing: bytes)

        #expect(reply.responseCode == .noError)
        #expect(reply.addresses == ["198.51.100.7", "203.0.113.9"])
    }

    @Test
    func rejectsAQuery() {
        #expect(throws: DNSReplyError.notAReply) {
            try DNSReply(parsing: [0x12, 0x34, 0x01, 0x00, 0, 1, 0, 0, 0, 0, 0, 0] + Self.question)
        }
    }

    @Test(arguments: [4, 12, 20])
    func rejectsATruncatedReply(_ length: Int) {
        let bytes =
            [0x12, 0x34, 0x81, 0x80, 0, 1, 0, 1, 0, 0, 0, 0] + Self.question
            + [0xC0, 0x0C, 0, 1, 0, 1, 0, 0, 0, 60, 0, 4, 198, 51, 100, 7]

        #expect(throws: DNSReplyError.truncated) {
            try DNSReply(parsing: Array(bytes.prefix(length)))
        }
    }

    @Test
    func namesAnUnknownResponseCode() throws {
        let reply = try DNSReply(parsing: [0x12, 0x34, 0x81, 0x0B, 0, 0, 0, 0, 0, 0, 0, 0])

        #expect(reply.responseCode == .other(11))
        #expect(reply.responseCode.description == "RCODE11")
    }
}
