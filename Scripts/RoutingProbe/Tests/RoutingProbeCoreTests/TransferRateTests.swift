import RoutingProbeCore
import Testing

@Suite
struct TransferRateTests {
    @Test
    func convertsBytesPerSecondToMegabitsPerSecond() throws {
        let rate = try #require(TransferRate(byteCount: 25_000_000, duration: .seconds(2)))

        #expect(rate.megabitsPerSecond == 100)
    }

    @Test
    func countsFractionsOfASecond() throws {
        let rate = try #require(TransferRate(byteCount: 1_000_000, duration: .milliseconds(500)))

        #expect(rate.megabitsPerSecond == 16)
    }

    @Test
    func hasNoRateWithoutElapsedTime() {
        #expect(TransferRate(byteCount: 1_000, duration: .zero) == nil)
    }
}
