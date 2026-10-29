import Foundation
import ProviderMessaging
import Testing

@Suite
struct TunnelStopReasonTests {
    @Test(arguments: TunnelStopReason.allCases)
    func survivesTheTripThroughAnError(_ reason: TunnelStopReason) {
        #expect(TunnelStopReason(error: reason.error) == reason)
    }

    @Test
    func ignoresErrorsThatDidNotComeFromTheTunnel() {
        #expect(TunnelStopReason(error: NSError(domain: NSPOSIXErrorDomain, code: 1)) == nil)
        #expect(TunnelStopReason(error: NSError(domain: TunnelStopReason.errorDomain, code: 999)) == nil)
    }
}
