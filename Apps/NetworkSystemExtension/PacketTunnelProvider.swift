import NetworkExtension
import Security
import os

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private let logger = Logger(subsystem: SecretsSpikeNames.subsystem, category: "Provider")

    override nonisolated(nonsending) func startTunnel(options: [String: NSObject]?) async throws {
        reportPasswordReference()
        reportProviderConfiguration()
        throw ProviderStartFailure.tunnelEngineNotIntegrated
    }

    override func stopTunnel(with reason: NEProviderStopReason) async {}

    private func reportPasswordReference() {
        guard let reference = protocolConfiguration.passwordReference else {
            logger.log("SP-5 variant A: no passwordReference")
            return
        }
        let query: [CFString: Any] = [kSecValuePersistentRef: reference, kSecReturnData: true]
        var result: CFTypeRef?
        let status = KeychainStatusDescription.of(SecItemCopyMatching(query as CFDictionary, &result))
        let fingerprint = (result as? Data).map(SecretFingerprint.of) ?? "none"
        logger.log("SP-5 variant A: \(status, privacy: .public), fingerprint \(fingerprint, privacy: .public)")
    }

    private func reportProviderConfiguration() {
        let configuration = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration
        let secret = configuration?[SecretsSpikeNames.providerConfigurationKey] as? String
        let fingerprint = secret.map { text in SecretFingerprint.of(Data(text.utf8)) } ?? "none"
        logger.log("SP-5 variant C: fingerprint \(fingerprint, privacy: .public)")
    }
}
