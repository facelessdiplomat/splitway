import Foundation

public struct MeasurementLine: Sendable {
    private static let missingValue = "none"
    private static let millisecondsPerSecond = 1_000.0

    private let name: String
    private let fields: [(String, String)]

    public init(_ name: String, fields: [(String, String)]) {
        self.name = name
        self.fields = fields
    }

    public var text: String {
        ([name] + fields.map { field, value in "\(field)=\(value)" }).joined(separator: " ")
    }

    public static func milliseconds(_ interval: TimeInterval?) -> String {
        guard let interval else { return missingValue }
        return String(format: "%.1f", interval * millisecondsPerSecond)
    }

    public static func megabitsPerSecond(_ rate: TransferRate?) -> String {
        guard let rate else { return missingValue }
        return String(format: "%.1f", rate.megabitsPerSecond)
    }

    public static func seconds(_ duration: Duration) -> String {
        String(format: "%.2f", duration.seconds)
    }
}
