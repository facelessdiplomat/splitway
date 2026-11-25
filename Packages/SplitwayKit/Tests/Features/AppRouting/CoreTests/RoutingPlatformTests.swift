import AppRouting
import Testing

@Suite
struct RoutingPlatformTests {
    @Test
    func routesAllTrafficOrSelectedApplicationsOnMac() {
        #expect(RoutingPlatform.macOS.supportedModes == [.allTraffic, .selectedApplications])
    }

    @Test
    func routesOnlyAllTrafficOnIPhoneAndIPad() {
        #expect(RoutingPlatform.iOS.supportedModes == [.allTraffic])
    }
}
