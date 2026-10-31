import Foundation
import RoutingProbeCore
import Testing

@Suite
struct ProbeRequestTests {
    static let address = "https://example.com/file"

    @Test
    func treatsNoArgumentsAsTheRoutingCheck() throws {
        #expect(try ProbeRequest(arguments: []) == .routing)
    }

    @Test
    func takesThreeDownloadAttemptsByDefault() throws {
        let request = try ProbeRequest(arguments: ["download", Self.address])

        #expect(request == .download(try #require(URL(string: Self.address)), attempts: 3))
    }

    @Test
    func takesTheDownloadAttemptCountFromTheArguments() throws {
        let request = try ProbeRequest(arguments: ["download", Self.address, "5"])

        #expect(request == .download(try #require(URL(string: Self.address)), attempts: 5))
    }

    @Test
    func takesTheUploadByteCountFromTheArguments() throws {
        let request = try ProbeRequest(arguments: ["upload", Self.address, "2", "10000000"])

        #expect(request == .upload(try #require(URL(string: Self.address)), attempts: 2, byteCount: 10_000_000))
    }

    @Test
    func uploadsTwentyFiveMegabytesThreeTimesByDefault() throws {
        let request = try ProbeRequest(arguments: ["upload", Self.address])

        #expect(request == .upload(try #require(URL(string: Self.address)), attempts: 3, byteCount: 25_000_000))
    }

    @Test
    func takesTenLatencyAttemptsByDefault() throws {
        let request = try ProbeRequest(arguments: ["latency", Self.address])

        #expect(request == .latency(try #require(URL(string: Self.address)), attempts: 10))
    }

    @Test
    func startsABackgroundDownloadFiveSecondsLaterByDefault() throws {
        let request = try ProbeRequest(arguments: ["background-start", Self.address])

        #expect(request == .backgroundStart(try #require(URL(string: Self.address)), delaySeconds: 5))
    }

    @Test
    func takesTheBackgroundDelayFromTheArguments() throws {
        let request = try ProbeRequest(arguments: ["background-start", Self.address, "8"])

        #expect(request == .backgroundStart(try #require(URL(string: Self.address)), delaySeconds: 8))
    }

    @Test
    func waitsThirtySecondsForABackgroundDownloadByDefault() throws {
        #expect(try ProbeRequest(arguments: ["background-collect"]) == .backgroundCollect(timeoutSeconds: 30))
    }

    @Test
    func takesTheCollectionTimeoutFromTheArguments() throws {
        #expect(try ProbeRequest(arguments: ["background-collect", "45"]) == .backgroundCollect(timeoutSeconds: 45))
    }

    @Test
    func rejectsAnUnknownMode() {
        #expect(throws: ProbeRequestError.unknownMode("stream")) {
            try ProbeRequest(arguments: ["stream", Self.address])
        }
    }

    @Test
    func rejectsAMeasurementWithoutAnAddress() {
        #expect(throws: ProbeRequestError.missingAddress) {
            try ProbeRequest(arguments: ["latency"])
        }
    }

    @Test(arguments: ["example.com/file", "ftp://example.com/file", "https://"])
    func rejectsAnAddressThatIsNotHTTP(_ address: String) {
        #expect(throws: ProbeRequestError.invalidAddress(address)) {
            try ProbeRequest(arguments: ["download", address])
        }
    }

    @Test(arguments: ["0", "-2", "three"])
    func rejectsACountThatIsNotPositive(_ count: String) {
        #expect(throws: ProbeRequestError.invalidCount(count)) {
            try ProbeRequest(arguments: ["download", Self.address, count])
        }
    }
}
