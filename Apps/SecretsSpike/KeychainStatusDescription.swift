import Foundation
import Security

enum KeychainStatusDescription {
    static func of(_ status: OSStatus) -> String {
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "unknown"
        return "\(status) (\(message))"
    }
}
