import DNSProxy
import SharedKernelTestSupport
import Testing

@Suite
struct DNSRefusalResponseBuilderTests {
    private static let exampleQuestion = DNSMessageFixtures.question(
        DNSMessageFixtures.name("example.com"), type: DNSMessageFixtures.addressType)

    @Test
    func refusesAnAddressQueryWithItsIdentifierAndQuestion() throws {
        let query = DNSMessageFixtures.message(id: 0x1234, flags: 0x0100, questions: [Self.exampleQuestion])

        let response = try DNSRefusalResponseBuilder.response(refusing: query)

        #expect(response == DNSMessageFixtures.message(id: 0x1234, flags: 0x8105, questions: [Self.exampleQuestion]))
    }

    @Test
    func refusesAnIPv6AddressQueryWithoutRecursion() throws {
        let question = DNSMessageFixtures.question(
            DNSMessageFixtures.name("ipv6.example.org"), type: DNSMessageFixtures.ipv6AddressType)
        let query = DNSMessageFixtures.message(id: 0xBEEF, flags: 0x0000, questions: [question])

        let response = try DNSRefusalResponseBuilder.response(refusing: query)

        #expect(response == DNSMessageFixtures.message(id: 0xBEEF, flags: 0x8005, questions: [question]))
    }

    @Test(arguments: [true, false])
    func answersAnExtendedQueryWithItsOwnOptionRecord(acceptsDNSSECRecords: Bool) throws {
        let clientOptions = DNSMessageFixtures.optionRecord(
            payloadByteCount: 4096,
            acceptsDNSSECRecords: acceptsDNSSECRecords,
            options: DNSMessageFixtures.cookieOption
        )
        let query = DNSMessageFixtures.message(
            id: 0x0042, flags: 0x0110, questions: [Self.exampleQuestion], additionalRecords: [clientOptions])

        let response = try DNSRefusalResponseBuilder.response(refusing: query)

        let serverOptions = DNSMessageFixtures.optionRecord(
            payloadByteCount: 1232, acceptsDNSSECRecords: acceptsDNSSECRecords)
        #expect(
            response
                == DNSMessageFixtures.message(
                    id: 0x0042, flags: 0x8115, questions: [Self.exampleQuestion], additionalRecords: [serverOptions])
        )
    }

    @Test
    func keepsEveryQuestionOfAQueryWithSeveralQuestions() throws {
        let compressedName: [UInt8] = [0xC0, 0x0C]
        let questions = [
            Self.exampleQuestion,
            DNSMessageFixtures.question(compressedName, type: DNSMessageFixtures.ipv6AddressType),
        ]
        let query = DNSMessageFixtures.message(id: 0x7777, flags: 0x0100, questions: questions)

        let response = try DNSRefusalResponseBuilder.response(refusing: query)

        #expect(response == DNSMessageFixtures.message(id: 0x7777, flags: 0x8105, questions: questions))
    }

    @Test
    func rejectsAMessageShorterThanAHeader() {
        let query = Array(DNSMessageFixtures.message(id: 1, flags: 0x0100, questions: []).prefix(11))

        #expect(throws: DNSMessageError.truncatedHeader) {
            try DNSRefusalResponseBuilder.response(refusing: query)
        }
    }

    @Test
    func rejectsAResponse() {
        let response = DNSMessageFixtures.message(id: 1, flags: 0x8180, questions: [Self.exampleQuestion])

        #expect(throws: DNSMessageError.notAQuery) {
            try DNSRefusalResponseBuilder.response(refusing: response)
        }
    }

    @Test
    func rejectsAQueryWithATruncatedQuestion() {
        let query = DNSMessageFixtures.message(id: 1, flags: 0x0100, questions: [Self.exampleQuestion])

        #expect(throws: DNSMessageError.malformedQuestion) {
            try DNSRefusalResponseBuilder.response(refusing: Array(query.dropLast(3)))
        }
    }

    @Test
    func rejectsAQueryThatAnnouncesAMissingAdditionalRecord() {
        let query = DNSMessageFixtures.message(
            id: 1, flags: 0x0100, questions: [Self.exampleQuestion], additionalCount: 1)

        #expect(throws: DNSMessageError.malformedRecord) {
            try DNSRefusalResponseBuilder.response(refusing: query)
        }
    }

    @Test
    func neverCrashesOnArbitraryBytes() {
        var generator = SeededRandomNumberGenerator(seed: 2026)
        let validQuery = DNSMessageFixtures.message(id: 0x1234, flags: 0x0100, questions: [Self.exampleQuestion])

        for _ in 0..<20_000 {
            var bytes = Array(validQuery.prefix(Int.random(in: 0...validQuery.count, using: &generator)))
            for _ in 0..<Int.random(in: 0...6, using: &generator) where !bytes.isEmpty {
                bytes[Int.random(in: 0..<bytes.count, using: &generator)] = UInt8.random(in: 0...255, using: &generator)
            }
            let response = try? DNSRefusalResponseBuilder.response(refusing: bytes)

            #expect(response.map { refusal in Array(refusal.prefix(2)) == Array(bytes.prefix(2)) } ?? true)
        }
    }
}
