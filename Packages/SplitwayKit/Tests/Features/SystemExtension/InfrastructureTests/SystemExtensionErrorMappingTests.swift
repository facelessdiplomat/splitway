import Foundation
import SystemExtension
import SystemExtensionInfrastructure
import SystemExtensions
import Testing

@Suite
struct SystemExtensionErrorMappingTests {
    @Test(arguments: [
        (
            OSSystemExtensionError.Code.unsupportedParentBundleLocation,
            SystemExtensionFailure.appNotInApplicationsFolder
        ),
        (.missingEntitlement, .invalidInstallation),
        (.codeSignatureInvalid, .invalidInstallation),
        (.validationFailed, .invalidInstallation),
        (.extensionNotFound, .invalidInstallation),
        (.forbiddenBySystemPolicy, .forbiddenBySystemPolicy),
        (.authorizationRequired, .authorizationRequired),
        (.requestCanceled, .cancelled),
        (.requestSuperseded, .cancelled),
        (.unknown, .unknown),
    ])
    func explainsWhyActivationFailed(code: OSSystemExtensionError.Code, failure: SystemExtensionFailure) {
        let error = NSError(domain: OSSystemExtensionErrorDomain, code: code.rawValue)

        #expect(SystemExtensionErrorMapping.failure(for: error) == failure)
    }

    @Test
    func treatsForeignErrorsAsUnknown() {
        #expect(SystemExtensionErrorMapping.failure(for: CocoaError(.fileReadUnknown)) == .unknown)
    }
}
