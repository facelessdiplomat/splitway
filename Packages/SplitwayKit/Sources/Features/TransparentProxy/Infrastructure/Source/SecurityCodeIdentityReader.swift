import Foundation
import Security
import TransparentProxy

public struct SecurityCodeIdentityReader: CodeIdentityReader {
    private static let appleAnchorRequirementText = "anchor apple"

    public init() {}

    public func codeIdentity(of auditToken: AuditToken) throws(CodeIdentityReadingError) -> CodeIdentity {
        try Self.codeIdentity(of: try Self.guestCode(of: auditToken))
    }

    static func codeIdentity(of code: SecCode) throws(CodeIdentityReadingError) -> CodeIdentity {
        let details = try signingDetails(of: code)
        let executableURL = details[kSecCodeInfoMainExecutable as String] as? URL
        return CodeIdentity(
            signingIdentifier: details[kSecCodeInfoIdentifier as String] as? String,
            teamIdentifier: details[kSecCodeInfoTeamIdentifier as String] as? String,
            executablePath: executableURL?.resolvingSymlinksInPath().path(percentEncoded: false),
            isSignedByApple: isSignedByApple(code)
        )
    }

    private static func guestCode(of auditToken: AuditToken) throws(CodeIdentityReadingError) -> SecCode {
        let attributes = [kSecGuestAttributeAudit as String: Data(auditToken.bytes)] as CFDictionary
        var code: SecCode?
        guard SecCodeCopyGuestWithAttributes(nil, attributes, [], &code) == errSecSuccess, let code else {
            throw .processUnavailable
        }
        return code
    }

    private static func signingDetails(of code: SecCode) throws(CodeIdentityReadingError) -> [String: Any] {
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else {
            throw .unreadableCode
        }
        var information: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
        guard SecCodeCopySigningInformation(staticCode, flags, &information) == errSecSuccess,
            let details = information as? [String: Any]
        else { throw .unreadableCode }
        return details
    }

    private static func isSignedByApple(_ code: SecCode) -> Bool {
        var requirement: SecRequirement?
        guard
            SecRequirementCreateWithString(appleAnchorRequirementText as CFString, [], &requirement)
                == errSecSuccess,
            let requirement
        else { return false }
        return SecCodeCheckValidity(code, [], requirement) == errSecSuccess
    }
}
