import Foundation
@preconcurrency import NetworkExtension
import os

@MainActor
enum DNSProxySpikeRunner {
    private static let enableArgument = "-SplitwayDNSProxySpikeEnable"
    private static let disableArgument = "-SplitwayDNSProxySpikeDisable"
    private static let extensionIdentifierSuffix = ".network-extension"
    private static let slotName = "Splitway"
    private static let logger = Logger(subsystem: "Splitway.DNSProxySpike", category: "Application")

    static func runIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains(enableArgument) {
            Task { await configure(isEnabled: true) }
        } else if arguments.contains(disableArgument) {
            Task { await configure(isEnabled: false) }
        }
    }

    private static func configure(isEnabled: Bool) async {
        let manager = NEDNSProxyManager.shared()
        do {
            try await manager.loadFromPreferences()
            let providerProtocol = NEDNSProxyProviderProtocol()
            providerProtocol.providerBundleIdentifier = (Bundle.main.bundleIdentifier ?? "") + extensionIdentifierSuffix
            manager.providerProtocol = providerProtocol
            manager.localizedDescription = slotName
            manager.isEnabled = isEnabled
            try await manager.saveToPreferences()
            logger.info("SP-9 DNS proxy configuration saved, enabled \(isEnabled, privacy: .public)")
        } catch {
            logger.error("SP-9 DNS proxy configuration failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
