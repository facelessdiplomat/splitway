import DNSProxy
import DNSProxyTestSupport
import SharedKernel
import Testing

@Suite
struct DNSAddressAnswersTests {
    @Test
    func readsTheAddressesOfTheQuestionWithTheirTimeToLive() throws {
        let response = DNSResponseFixture.response(
            to: "example.com",
            answers: [
                .address(try IPAddress("192.0.2.10"), timeToLive: 300),
                .address(try IPAddress("2001:db8::10"), timeToLive: 60),
            ])

        let answers = try DNSAddressAnswers(parsing: response)

        #expect(answers.name == (try DomainName("example.com")))
        #expect(
            answers.records == [
                DNSAddressRecord(address: try IPAddress("192.0.2.10"), timeToLive: 300),
                DNSAddressRecord(address: try IPAddress("2001:db8::10"), timeToLive: 60),
            ])
    }

    @Test
    func keepsTheAddressesBehindAnAlias() throws {
        let response = DNSResponseFixture.response(
            to: "www.example.com",
            answers: [
                .alias("cdn.example.net", timeToLive: 120),
                .address(try IPAddress("198.51.100.7"), timeToLive: 30),
            ])

        let answers = try DNSAddressAnswers(parsing: response)

        #expect(answers.name == (try DomainName("www.example.com")))
        #expect(answers.records.map(\.address) == [try IPAddress("198.51.100.7")])
    }

    @Test
    func takesTheNameOfTheQuestionInLowercase() throws {
        let response = DNSResponseFixture.response(to: "Example.COM", answers: [])

        #expect(try DNSAddressAnswers(parsing: response).name == (try DomainName("example.com")))
    }

    @Test(arguments: [UInt8(2), 3, 5])
    func hasNoAddressesWhenTheResolverReportsAnError(responseCode: UInt8) throws {
        let response = DNSResponseFixture.response(
            to: "example.com",
            answers: [.address(try IPAddress("192.0.2.10"), timeToLive: 60)],
            responseCode: responseCode
        )

        #expect(try DNSAddressAnswers(parsing: response).records.isEmpty)
    }

    @Test
    func rejectsAQuery() {
        #expect(throws: DNSMessageError.notAResponse) {
            try DNSAddressAnswers(parsing: DNSResponseFixture.query(for: "example.com"))
        }
    }

    @Test
    func rejectsATruncatedHeader() {
        #expect(throws: DNSMessageError.truncatedHeader) {
            try DNSAddressAnswers(parsing: [0x2A, 0x2A, 0x81])
        }
    }

    @Test
    func rejectsAnAnswerThatEndsEarly() throws {
        let response = DNSResponseFixture.response(
            to: "example.com", answers: [.address(try IPAddress("192.0.2.10"), timeToLive: 60)])

        #expect(throws: DNSMessageError.malformedRecord) {
            try DNSAddressAnswers(parsing: Array(response.dropLast(2)))
        }
    }

    @Test
    func rejectsANamePointerThatPointsAtItself() {
        let header: [UInt8] = [0x2A, 0x2A, 0x81, 0x80, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        let selfPointingQuestion: [UInt8] = [0xC0, 0x0C, 0x00, 0x01, 0x00, 0x01]

        #expect(throws: DNSMessageError.malformedQuestion) {
            try DNSAddressAnswers(parsing: header + selfPointingQuestion)
        }
    }

    @Test
    func rejectsAResponseToSeveralQuestions() {
        var response = DNSResponseFixture.response(to: "example.com", answers: [])
        response[5] = 2

        #expect(throws: DNSMessageError.malformedQuestion) {
            try DNSAddressAnswers(parsing: response)
        }
    }
}
