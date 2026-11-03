import Foundation
import TunnelConfiguration

final class TestPeerProcess {
    struct Announcement: Decodable {
        let publicKey: String
        let listenPort: Int
    }

    enum Failure: Error {
        case missingExecutable(String)
        case noAnnouncement
    }

    private static let newline = UInt8(ascii: "\n")

    let announcement: Announcement
    private let process = Process()
    private let input = Pipe()
    private let output = Pipe()

    private static let buildScript = "Packages/TunnelCore/Scripts/build-test-peer.sh"

    init(clientPublicKey: PublicKey) throws {
        let executable = Self.executableURL()
        let executablePath = executable.path(percentEncoded: false)
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            throw Failure.missingExecutable("\(executablePath) is missing, run \(Self.buildScript)")
        }
        process.executableURL = executable
        process.arguments = ["-client-public-key", clientPublicKey.hexEncodedText]
        process.standardInput = input
        process.standardOutput = output
        try process.run()
        announcement = try JSONDecoder().decode(
            Announcement.self, from: Self.firstLine(of: output.fileHandleForReading))
    }

    func stop() {
        try? input.fileHandleForWriting.close()
        process.waitUntilExit()
    }

    private static func executableURL() -> URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "Artifacts/testpeer")
    }

    private static func firstLine(of handle: FileHandle) throws -> Data {
        var line = Data()
        while !line.contains(newline) {
            let chunk = handle.availableData
            guard !chunk.isEmpty else { throw Failure.noAnnouncement }
            line.append(chunk)
        }
        return line
    }
}
