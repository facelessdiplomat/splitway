import RoutingProbeCore
import Testing

@Suite
struct MeasurementLineTests {
    @Test
    func joinsTheNameAndTheFieldsInOrder() {
        let line = MeasurementLine("download 2", fields: [("bytes", "100"), ("mbps", "8.0")])

        #expect(line.text == "download 2 bytes=100 mbps=8.0")
    }

    @Test
    func showsMillisecondsWithOneDecimal() {
        #expect(MeasurementLine.milliseconds(0.07346) == "73.5")
    }

    @Test
    func showsAMissingTimeAsNone() {
        #expect(MeasurementLine.milliseconds(nil) == "none")
    }

    @Test
    func showsARateWithOneDecimal() {
        #expect(MeasurementLine.megabitsPerSecond(TransferRate(byteCount: 1_234_567, duration: .seconds(1))) == "9.9")
    }

    @Test
    func showsAMissingRateAsNone() {
        #expect(MeasurementLine.megabitsPerSecond(nil) == "none")
    }
}
