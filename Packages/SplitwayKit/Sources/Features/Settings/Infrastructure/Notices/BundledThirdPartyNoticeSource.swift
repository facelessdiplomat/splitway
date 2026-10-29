import Foundation
import Settings

public struct BundledThirdPartyNoticeSource: ThirdPartyNoticeSource {
    private static let queue = DispatchQueue(label: "Splitway.ThirdPartyNotices", qos: .userInitiated)
    private static let manifestName = "ThirdPartyNotices"
    private static let manifestExtension = "json"
    private static let textExtension = "txt"

    public init() {}

    public func notices() async throws(ThirdPartyNoticeError) -> [ThirdPartyNotice] {
        try await Self.queuedNotices().get()
    }

    private static func queuedNotices() async -> Result<[ThirdPartyNotice], ThirdPartyNoticeError> {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: Result(catching: readNotices))
            }
        }
    }

    private static func readNotices() throws(ThirdPartyNoticeError) -> [ThirdPartyNotice] {
        let entries = try decodedManifest()
        return try entries.map { entry throws(ThirdPartyNoticeError) in
            ThirdPartyNotice(
                name: entry.name,
                licenseName: entry.license,
                dependencies: entry.dependencies,
                text: try text(named: entry.textFile)
            )
        }
    }

    private static func decodedManifest() throws(ThirdPartyNoticeError) -> [ThirdPartyNoticeManifestEntry] {
        guard let url = Bundle.module.url(forResource: manifestName, withExtension: manifestExtension),
            let data = try? Data(contentsOf: url),
            let entries = try? JSONDecoder().decode([ThirdPartyNoticeManifestEntry].self, from: data)
        else {
            throw .unavailable
        }
        return entries
    }

    private static func text(named name: String) throws(ThirdPartyNoticeError) -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: textExtension),
            let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            throw .unavailable
        }
        return text
    }
}
