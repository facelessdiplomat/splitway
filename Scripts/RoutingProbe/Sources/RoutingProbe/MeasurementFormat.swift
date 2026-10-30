import Foundation

enum MeasurementFormat {
    static func milliseconds(_ interval: TimeInterval?) -> String {
        guard let interval else { return "none" }
        return String(format: "%.1f", interval * 1_000)
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}
