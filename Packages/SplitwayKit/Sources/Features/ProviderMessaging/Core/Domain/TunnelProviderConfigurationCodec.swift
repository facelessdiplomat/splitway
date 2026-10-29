import Foundation

public enum TunnelProviderConfigurationCodec {
    public static let payloadKey = "SplitwayTunnel"
    public static let version = 1

    private static let coder = VersionedEnvelopeCoder()

    public static func dictionary(
        for configuration: TunnelProviderConfiguration
    ) throws(TunnelProviderConfigurationError) -> [String: Any] {
        do {
            return [payloadKey: try coder.encode(configuration, version: version)]
        } catch {
            throw .unencodable
        }
    }

    public static func configuration(
        from dictionary: [String: Any]?
    ) throws(TunnelProviderConfigurationError) -> TunnelProviderConfiguration {
        guard let payload = dictionary?[payloadKey] as? Data else { throw .missing }
        do {
            return try coder.decode(TunnelProviderConfiguration.self, from: payload, expectedVersion: version)
        } catch .unsupportedProtocolVersion(let found) {
            throw .unsupportedVersion(found)
        } catch {
            throw .malformed
        }
    }
}
