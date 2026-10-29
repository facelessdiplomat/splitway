import Foundation
import SharedKernel
import Testing

@Suite
struct SystemWallClockTests {
    @Test
    func reportsTheCurrentMoment() {
        let momentBefore = Date()

        let reportedMoment = SystemWallClock().now()

        let momentAfter = Date()
        #expect(reportedMoment >= momentBefore)
        #expect(reportedMoment <= momentAfter)
    }
}
