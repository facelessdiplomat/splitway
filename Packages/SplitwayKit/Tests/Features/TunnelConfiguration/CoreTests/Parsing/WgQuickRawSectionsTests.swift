import Testing
import TunnelConfiguration

@Suite
struct WgQuickRawSectionsTests {
    @Test
    func readsEveryEntryOfKnownSectionsAsWritten() {
        let text = """
            [Interface]
            PrivateKey = not a key
            MTU = 9

            [Unknown]
            Colour = blue

            [Peer]
            Endpoint = host
            """

        let sections = WgQuickConfigurationParser.rawSections(of: text)

        #expect(sections.map(\.section) == [.interface, .peer])
        #expect(sections.first?.entries.map(\.key) == ["PrivateKey", "MTU"])
        #expect(sections.first?.entries.map(\.value) == ["not a key", "9"])
        #expect(sections.last?.entries.map(\.line) == [9])
    }

    @Test
    func findsKeysWhateverTheirCase() {
        #expect(WgQuickKey(name: "allowedips") == .allowedIPs)
        #expect(WgQuickKey(name: "PostUp") == nil)
    }

    @Test
    func validatesValuesWithTheParserRules() throws {
        #expect(throws: ConfigurationValueError.mtu(.outOfRange)) {
            try WgQuickValueConversions.mtu("9")
        }
        #expect(try WgQuickValueConversions.networks("10.0.0.2/32, fd00::2/64").count == 2)
    }
}
