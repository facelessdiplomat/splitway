import Testing
import TunnelConfiguration

@Suite
struct PersistentKeepaliveTests {
    @Test(arguments: [("25", 25), ("1", 1), ("65535", 65_535)])
    func parsesIntervalsInSeconds(text: String, seconds: Int) throws {
        #expect(try PersistentKeepalive.parse(text)?.seconds == seconds)
    }

    @Test(arguments: ["0", "off", "Off", "OFF"])
    func treatsZeroAndOffAsDisabled(_ text: String) throws {
        #expect(try PersistentKeepalive.parse(text) == nil)
    }

    @Test(arguments: ["", "-1", "25s", "025"])
    func rejectsTextThatIsNotANumber(_ text: String) {
        #expect(throws: PersistentKeepaliveValidationError.notANumber) {
            try PersistentKeepalive.parse(text)
        }
    }

    @Test
    func rejectsIntervalsLongerThanTheProtocolAllows() {
        #expect(throws: PersistentKeepaliveValidationError.outOfRange) {
            try PersistentKeepalive.parse("65536")
        }
    }

    @Test
    func rejectsANonPositiveIntervalWhenBuiltDirectly() {
        #expect(throws: PersistentKeepaliveValidationError.outOfRange) {
            try PersistentKeepalive(seconds: 0)
        }
    }
}
