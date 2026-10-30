import Foundation

@main
struct RoutingProbeCommand {
    private static let defaultDownloadCount = 3
    private static let defaultLatencyCount = 10
    private static let defaultUploadByteCount = 25_000_000

    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let lines: [String]
        switch (arguments.first, arguments.dropFirst().first.flatMap(URL.init(string:))) {
        case ("download", .some(let address)):
            let count = arguments.dropFirst(2).first.flatMap(Int.init) ?? defaultDownloadCount
            lines = await TransferMeasurement(direction: .download, address: address, count: max(count, 1)).run()
        case ("upload", .some(let address)):
            let count = arguments.dropFirst(2).first.flatMap(Int.init) ?? defaultDownloadCount
            let byteCount = arguments.dropFirst(3).first.flatMap(Int.init) ?? defaultUploadByteCount
            let direction = TransferMeasurement.Direction.upload(byteCount: max(byteCount, 1))
            lines = await TransferMeasurement(direction: direction, address: address, count: max(count, 1)).run()
        case ("latency", .some(let address)):
            let count = arguments.dropFirst(2).first.flatMap(Int.init) ?? defaultLatencyCount
            lines = await LatencyMeasurement(address: address, count: max(count, 1)).run()
        default:
            lines = [await AddressProbe().run(), DNSProbe().run(), ConnectionProbe().run()].map(\.text)
        }
        FileHandle.standardOutput.write(Data((lines.joined(separator: "\n") + "\n").utf8))
    }
}
