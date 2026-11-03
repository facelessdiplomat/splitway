import Foundation
import Testing

@Suite
final class SecretLeakScannerTests {
    private let fixture = LeakScanFixture()
    private let workspace: LeakScanWorkspace

    init() throws {
        workspace = try LeakScanWorkspace()
    }

    deinit {
        workspace.removeEverything()
    }

    @Test
    func findsAKeyPlantedInAContainerFileInBase64() throws {
        _ = try workspace.plant(Data(fixture.configurationText.utf8), named: "planted.conf")

        let leaks = scanAppGroupContainer()

        #expect(leaks.contains { leak in leak.hasPrefix("private key in base64 in ") })
    }

    @Test
    func findsAKeyPlantedInAContainerFileInHex() throws {
        let key = try #require(fixture.secrets["private key"])
        let hex = key.map { byte in String(format: "%02x", byte) }.joined()
        _ = try workspace.plant(Data(hex.utf8), named: "planted.txt")

        let leaks = scanAppGroupContainer()

        #expect(leaks.contains { leak in leak.hasPrefix("private key in hex in ") })
    }

    @Test
    func findsAKeyPlantedInAContainerFileAsRawBytes() throws {
        let key = try #require(fixture.secrets["preshared key"])
        _ = try workspace.plant(Data([0x00]) + key + Data([0xFF]), named: "planted.bin")

        let leaks = scanAppGroupContainer()

        #expect(leaks.contains { leak in leak.hasPrefix("preshared key as raw bytes in ") })
    }

    private func scanAppGroupContainer() -> [String] {
        SecretLeakScanner(secrets: fixture.secrets).leaks(inFilesUnder: workspace.appGroupContainer)
    }
}
