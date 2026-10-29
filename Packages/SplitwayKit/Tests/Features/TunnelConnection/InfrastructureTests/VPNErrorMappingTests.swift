import Foundation
import NetworkExtension
import ProviderMessaging
import Testing
import TunnelConnection
import TunnelConnectionInfrastructure

@Suite
struct VPNErrorMappingTests {
    @Test
    func treatsAnUnwritableConfigurationAsADeclinedPermission() {
        let declined = NSError(domain: NEVPNErrorDomain, code: NEVPNError.Code.configurationReadWriteFailed.rawValue)

        #expect(VPNErrorMapping.failureOfSaving(declined) == .permissionDenied)
    }

    @Test
    func treatsOtherSavingErrorsAsAnUnavailableSystemConfiguration() {
        let invalid = NSError(domain: NEVPNErrorDomain, code: NEVPNError.Code.configurationInvalid.rawValue)

        #expect(VPNErrorMapping.failureOfSaving(invalid) == .systemConfigurationUnavailable)
        #expect(VPNErrorMapping.failureOfSaving(CocoaError(.fileWriteUnknown)) == .systemConfigurationUnavailable)
    }

    @Test
    func explainsDisconnectsCausedByTheTunnel() {
        #expect(
            VPNErrorMapping.failureOfDisconnect(TunnelStopReason.engineSocketsUnavailable.error)
                == .engineFailed(.socketsUnavailable)
        )
        #expect(VPNErrorMapping.failureOfDisconnect(NSError(domain: NEVPNConnectionErrorDomain, code: 1)) == .unknown)
    }
}
