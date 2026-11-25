extension [Double] {
    var median: Double? {
        guard !isEmpty else { return nil }
        let ordered = sorted()
        let middle = ordered.count / 2
        return ordered.count.isMultiple(of: 2) ? (ordered[middle - 1] + ordered[middle]) / 2 : ordered[middle]
    }
}
