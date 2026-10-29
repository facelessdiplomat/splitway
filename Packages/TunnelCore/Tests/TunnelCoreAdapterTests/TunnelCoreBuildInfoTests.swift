import Testing
import TunnelCoreAdapter

@Suite
struct TunnelCoreBuildInfoTests {
    @Test
    func reportsTheSemanticVersionOfTheGoCore() {
        let version = TunnelCoreBuildInfo.version

        #expect(version.wholeMatch(of: /\d+\.\d+\.\d+/) != nil)
    }
}
