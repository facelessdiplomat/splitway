import PacketTunnelInfrastructure
import Testing

@Suite
struct UtunDescriptorLocatorTests {
    @Test
    func findsNoTunnelInterfaceInAProcessThatHasNone() {
        #expect(UtunDescriptorLocator().tunnelFileDescriptor() == nil)
    }
}
