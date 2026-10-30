import Foundation

@main
struct RoutingProbeCommand {
    static func main() async {
        let lines = [await AddressProbe().run(), DNSProbe().run(), ConnectionProbe().run()]
        let output = lines.map(\.text).joined(separator: "\n") + "\n"
        FileHandle.standardOutput.write(Data(output.utf8))
    }
}
