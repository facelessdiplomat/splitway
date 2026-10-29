import Foundation
import SharedKernel
import TunnelConfiguration

extension ConfigurationValueError {
    public var message: LocalizedStringResource {
        switch self {
        case .key:
            .moduleResource("Enter a 44-character base64 key.")
        case .network:
            .moduleResource("Enter addresses like 10.0.0.2/32, separated by commas.")
        case .port:
            Self.message(for: NetworkPort.validRange) { lower, upper in
                .moduleResource("Enter a port from \(lower) to \(upper).")
            }
        case .mtu:
            Self.message(for: MTU.supportedRange) { lower, upper in
                .moduleResource("Enter an MTU from \(lower) to \(upper).")
            }
        case .persistentKeepalive:
            Self.message(for: PersistentKeepalive.validIntervalRange) { lower, upper in
                .moduleResource("Enter seconds from \(lower) to \(upper), or 0 to turn it off.")
            }
        case .endpoint:
            .moduleResource("Enter a host and port, like vpn.example.com:51820.")
        case .dns:
            .moduleResource("Enter DNS servers or search domains, separated by commas.")
        }
    }

    private static func message(
        for range: ClosedRange<Int>,
        _ message: (String, String) -> LocalizedStringResource
    ) -> LocalizedStringResource {
        message(String(range.lowerBound), String(range.upperBound))
    }
}
