import Testing
import TunnelConfiguration
import TunnelConfigurationTestSupport
import TunnelEditor
import TunnelLibrary

enum TunnelDraftFixtures {
    static func configuration(_ text: String) throws -> TunnelConfiguration {
        try #require(WgQuickConfigurationParser.parse(text).configuration)
    }

    static func fullDraft() throws -> TunnelDraft {
        TunnelDraft(name: try TunnelName("Office"), configuration: try configuration(WgQuickFixtures.full))
    }
}
