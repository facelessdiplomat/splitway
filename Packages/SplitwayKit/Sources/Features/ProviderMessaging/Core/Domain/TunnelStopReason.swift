import Foundation

public enum TunnelStopReason: Int, Sendable, Hashable, CaseIterable {
    case configurationUnavailable = 1
    case unsupportedRoutingMode = 2
    case endpointUnresolvable = 3
    case networkSettingsRejected = 4
    case tunnelInterfaceUnavailable = 5
    case engineConfigurationRejected = 6
    case engineSocketsUnavailable = 7
    case engineFailure = 8

    public static let errorDomain = "Splitway.TunnelStop"

    public init?(error: any Error) {
        let systemError = error as NSError
        guard systemError.domain == Self.errorDomain else { return nil }
        self.init(rawValue: systemError.code)
    }

    public var error: NSError {
        NSError(domain: Self.errorDomain, code: rawValue)
    }
}
