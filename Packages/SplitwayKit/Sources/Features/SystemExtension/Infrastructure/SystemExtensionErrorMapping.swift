#if os(macOS)
    import Foundation
    import SystemExtension
    import SystemExtensions

    public enum SystemExtensionErrorMapping {
        public static func failure(for error: any Error) -> SystemExtensionFailure {
            let systemError = error as NSError
            guard systemError.domain == OSSystemExtensionErrorDomain,
                let code = OSSystemExtensionError.Code(rawValue: systemError.code)
            else { return .unknown }
            switch code {
            case .unsupportedParentBundleLocation:
                return .appNotInApplicationsFolder
            case .missingEntitlement, .codeSignatureInvalid, .validationFailed, .extensionNotFound,
                .extensionMissingIdentifier, .unknownExtensionCategory:
                return .invalidInstallation
            case .forbiddenBySystemPolicy:
                return .forbiddenBySystemPolicy
            case .authorizationRequired:
                return .authorizationRequired
            case .requestCanceled, .requestSuperseded:
                return .cancelled
            default:
                return .unknown
            }
        }

        static func isCancellation(_ error: any Error) -> Bool {
            let systemError = error as NSError
            return systemError.domain == OSSystemExtensionErrorDomain
                && systemError.code == OSSystemExtensionError.Code.requestCanceled.rawValue
        }
    }
#endif
