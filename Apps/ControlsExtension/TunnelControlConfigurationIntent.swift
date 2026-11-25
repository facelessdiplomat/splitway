import AppIntents

struct TunnelControlConfigurationIntent: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Splitway Tunnel"
    static let isDiscoverable = false

    @Parameter(title: "Tunnel", description: "The last connected tunnel when none is chosen.")
    var tunnel: TunnelEntity?
}
