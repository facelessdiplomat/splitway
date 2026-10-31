import Foundation
import RoutingProbeCore

@main
struct RoutingProbeCommand {
    private static let usage =
        "usage: RoutingProbe [download <url> [attempts] | upload <url> [attempts] [bytes] | latency <url> [attempts]]\n"
    private static let usageExitCode: Int32 = 2

    static func main() async {
        let request: ProbeRequest
        do {
            request = try ProbeRequest(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data(usage.utf8))
            exit(usageExitCode)
        }
        let output = await lines(answering: request).joined(separator: "\n") + "\n"
        FileHandle.standardOutput.write(Data(output.utf8))
    }

    private static func lines(answering request: ProbeRequest) async -> [String] {
        switch request {
        case .routing:
            [await AddressProbe().run(), DNSProbe().run(), ConnectionProbe().run()].map(\.text)
        case .download(let address, let attempts):
            await TransferMeasurement(direction: .download, address: address, attempts: attempts).run()
        case .upload(let address, let attempts, let byteCount):
            await TransferMeasurement(direction: .upload(byteCount: byteCount), address: address, attempts: attempts)
                .run()
        case .latency(let address, let attempts):
            await LatencyMeasurement(address: address, attempts: attempts).run()
        }
    }
}
