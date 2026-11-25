import AppRouting
import Testing

@Suite
struct RoutingPlatformTests {
    @Test
    func routesAllTrafficOrSelectedApplicationsOnMac() {
        #expect(RoutingPlatform.macOS.supportedModes == [.allTraffic, .selectedApplications])
    }

    @Test
    func routesAllTrafficOrSelectedServicesOnIPhoneAndIPad() {
        #expect(RoutingPlatform.iOS.supportedModes == [.allTraffic, .selectedServices])
    }
}
