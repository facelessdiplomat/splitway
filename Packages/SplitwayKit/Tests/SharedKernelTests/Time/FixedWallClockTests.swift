import Foundation
import SharedKernel
import SharedKernelTestSupport
import Testing

@Suite
struct FixedWallClockTests {
    @Test
    func alwaysReportsTheConfiguredMoment() {
        let configuredMoment = Date(timeIntervalSince1970: 1_800_000_000)
        let clock: any WallClock = FixedWallClock(configuredMoment)

        #expect(clock.now() == configuredMoment)
        #expect(clock.now() == configuredMoment)
    }
}
