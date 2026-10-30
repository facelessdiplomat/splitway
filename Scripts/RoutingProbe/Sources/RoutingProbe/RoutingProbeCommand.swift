import Foundation

@main
struct RoutingProbeCommand {
    private static let defaultDownloadCount = 3
    private static let defaultLatencyCount = 10

    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let lines: [String]
        switch (arguments.first, arguments.dropFirst().first.flatMap(URL.init(string:))) {
        case ("download", .some(let address)):
            let count = arguments.dropFirst(2).first.flatMap(Int.init) ?? defaultDownloadCount
            lines = await DownloadMeasurement(address: address, count: max(count, 1)).run()
        case ("latency", .some(let address)):
            let count = arguments.dropFirst(2).first.flatMap(Int.init) ?? defaultLatencyCount
            lines = await LatencyMeasurement(address: address, count: max(count, 1)).run()
        default:
            lines = [await AddressProbe().run(), DNSProbe().run(), ConnectionProbe().run()].map(\.text)
        }
        FileHandle.standardOutput.write(Data((lines.joined(separator: "\n") + "\n").utf8))
    }
}
