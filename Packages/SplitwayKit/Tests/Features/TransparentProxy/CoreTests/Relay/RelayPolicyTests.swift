import Testing
import TransparentProxy

@Suite
struct RelayPolicyTests {
    @Test
    func standardPolicyKeepsIdleConnectionsAsLongAsHomeRoutersDo() {
        #expect(RelayPolicy.standard.tcp.idleTimeout >= .seconds(2 * 60 * 60 + 4 * 60))
        #expect(RelayPolicy.standard.udp.idleTimeout >= .seconds(2 * 60))
    }

    @Test
    func standardPolicyReceivesTheLargestDatagram() {
        #expect(RelayPolicy.standard.udp.datagramBufferByteCount == UDPRelayPolicy.largestDatagramByteCount)
    }

    @Test
    func acceptsACustomPolicyWithinTheLimits() throws {
        let tcp = try TCPRelayPolicy(chunkByteCount: 4, connectTimeout: .seconds(1), idleTimeout: .seconds(2))
        let udp = try UDPRelayPolicy(datagramBufferByteCount: 512, idleTimeout: .seconds(3), maximumAssociations: 1)

        #expect(tcp.chunkByteCount == 4)
        #expect(udp.maximumAssociations == 1)
    }

    @Test
    func rejectsAnEmptyStreamChunk() {
        #expect(throws: RelayPolicyError.bufferSizeOutOfRange) {
            try TCPRelayPolicy(chunkByteCount: 0, connectTimeout: .seconds(1), idleTimeout: .seconds(1))
        }
    }

    @Test(arguments: [0, UDPRelayPolicy.largestDatagramByteCount + 1])
    func rejectsDatagramBuffersOutsideTheDatagramSizes(byteCount: Int) {
        #expect(throws: RelayPolicyError.bufferSizeOutOfRange) {
            try UDPRelayPolicy(datagramBufferByteCount: byteCount, idleTimeout: .seconds(1), maximumAssociations: 1)
        }
    }

    @Test
    func rejectsTimeoutsThatAreNotPositive() {
        #expect(throws: RelayPolicyError.nonPositiveTimeout) {
            try TCPRelayPolicy(chunkByteCount: 1, connectTimeout: .zero, idleTimeout: .seconds(1))
        }
        #expect(throws: RelayPolicyError.nonPositiveTimeout) {
            try TCPRelayPolicy(chunkByteCount: 1, connectTimeout: .seconds(1), idleTimeout: .seconds(-1))
        }
        #expect(throws: RelayPolicyError.nonPositiveTimeout) {
            try UDPRelayPolicy(datagramBufferByteCount: 1, idleTimeout: .zero, maximumAssociations: 1)
        }
    }

    @Test
    func rejectsAnAssociationLimitBelowOne() {
        #expect(throws: RelayPolicyError.nonPositiveAssociationLimit) {
            try UDPRelayPolicy(datagramBufferByteCount: 1, idleTimeout: .seconds(1), maximumAssociations: 0)
        }
    }
}
