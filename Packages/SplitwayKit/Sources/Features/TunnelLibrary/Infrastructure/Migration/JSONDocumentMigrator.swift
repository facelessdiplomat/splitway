import Foundation

public struct JSONDocumentMigrator: Sendable {
    public typealias UpgradeStep = @Sendable (inout [String: Any]) throws(JSONDocumentMigrationError) -> Void

    private static let versionKey = "schemaVersion"
    private static let firstVersion = 1

    private let upgradeSteps: [UpgradeStep]

    public init(upgradeSteps: [UpgradeStep]) {
        self.upgradeSteps = upgradeSteps
    }

    public var currentVersion: Int {
        Self.firstVersion + upgradeSteps.count
    }

    public func migrate(_ data: Data) throws(JSONDocumentMigrationError) -> Data {
        var document = try Self.object(from: data)
        let version = try Self.version(of: document)
        guard version != currentVersion else { return data }
        guard version < currentVersion else { throw .newerVersion(version) }
        for upgrade in upgradeSteps[(version - Self.firstVersion)...] {
            try upgrade(&document)
        }
        document[Self.versionKey] = currentVersion
        return try Self.data(from: document)
    }

    private static func object(from data: Data) throws(JSONDocumentMigrationError) -> [String: Any] {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw .malformedDocument
        }
        return object
    }

    private static func version(of document: [String: Any]) throws(JSONDocumentMigrationError) -> Int {
        guard let version = document[versionKey] as? Int, version >= firstVersion else {
            throw .malformedDocument
        }
        return version
    }

    private static func data(from document: [String: Any]) throws(JSONDocumentMigrationError) -> Data {
        guard JSONSerialization.isValidJSONObject(document),
            let data = try? JSONSerialization.data(withJSONObject: document)
        else {
            throw .malformedDocument
        }
        return data
    }
}
