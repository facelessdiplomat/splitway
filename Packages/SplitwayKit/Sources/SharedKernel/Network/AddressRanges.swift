struct AddressRanges: Sendable, Hashable {
    private let ranges: [ClosedRange<UInt128>]

    init() {
        ranges = []
    }

    init(merging unsortedRanges: [ClosedRange<UInt128>]) {
        ranges = Self.merged(unsortedRanges)
    }

    var isEmpty: Bool {
        ranges.isEmpty
    }

    func contains(_ value: UInt128) -> Bool {
        lastRange(startingAtOrBefore: value)?.contains(value) ?? false
    }

    func contains(_ range: ClosedRange<UInt128>) -> Bool {
        guard let candidate = lastRange(startingAtOrBefore: range.lowerBound) else { return false }
        return candidate.upperBound >= range.upperBound
    }

    func union(_ other: AddressRanges) -> AddressRanges {
        AddressRanges(merging: ranges + other.ranges)
    }

    func intersection(_ other: AddressRanges) -> AddressRanges {
        var overlaps: [ClosedRange<UInt128>] = []
        var ownIndex = 0
        var otherIndex = 0
        while ownIndex < ranges.count, otherIndex < other.ranges.count {
            let own = ranges[ownIndex]
            let foreign = other.ranges[otherIndex]
            if own.overlaps(foreign) {
                overlaps.append(max(own.lowerBound, foreign.lowerBound)...min(own.upperBound, foreign.upperBound))
            }
            if own.upperBound < foreign.upperBound {
                ownIndex += 1
            } else {
                otherIndex += 1
            }
        }
        return AddressRanges(merging: overlaps)
    }

    func subtracting(_ other: AddressRanges) -> AddressRanges {
        let removals = other.ranges
        var remainder: [ClosedRange<UInt128>] = []
        var firstRelevantIndex = 0
        for range in ranges {
            while firstRelevantIndex < removals.count, removals[firstRelevantIndex].upperBound < range.lowerBound {
                firstRelevantIndex += 1
            }
            remainder += Self.parts(of: range, notCoveredBy: removals[firstRelevantIndex...])
        }
        return AddressRanges(merging: remainder)
    }

    func networks(in family: IPAddressFamily) -> [IPNetwork] {
        ranges.flatMap { range in CIDRDecomposition.networks(covering: range, in: family) }
    }

    private func lastRange(startingAtOrBefore value: UInt128) -> ClosedRange<UInt128>? {
        var lowerIndex = 0
        var upperIndex = ranges.count
        while lowerIndex < upperIndex {
            let middleIndex = (lowerIndex + upperIndex) / 2
            if ranges[middleIndex].lowerBound <= value {
                lowerIndex = middleIndex + 1
            } else {
                upperIndex = middleIndex
            }
        }
        return lowerIndex == 0 ? nil : ranges[lowerIndex - 1]
    }

    private static func parts(
        of range: ClosedRange<UInt128>,
        notCoveredBy removals: ArraySlice<ClosedRange<UInt128>>
    ) -> [ClosedRange<UInt128>] {
        var parts: [ClosedRange<UInt128>] = []
        var uncoveredStart: UInt128? = range.lowerBound
        for removal in removals {
            guard let start = uncoveredStart, removal.lowerBound <= range.upperBound else { break }
            if removal.lowerBound > start {
                parts.append(start...(removal.lowerBound - 1))
            }
            uncoveredStart = removal.upperBound < range.upperBound ? removal.upperBound + 1 : nil
        }
        if let start = uncoveredStart {
            parts.append(start...range.upperBound)
        }
        return parts
    }

    private static func merged(_ unsortedRanges: [ClosedRange<UInt128>]) -> [ClosedRange<UInt128>] {
        var mergedRanges: [ClosedRange<UInt128>] = []
        for range in unsortedRanges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if let last = mergedRanges.last, touches(last, range) {
                mergedRanges[mergedRanges.count - 1] = last.lowerBound...max(last.upperBound, range.upperBound)
            } else {
                mergedRanges.append(range)
            }
        }
        return mergedRanges
    }

    private static func touches(_ earlier: ClosedRange<UInt128>, _ later: ClosedRange<UInt128>) -> Bool {
        earlier.upperBound == .max || later.lowerBound <= earlier.upperBound + 1
    }
}
