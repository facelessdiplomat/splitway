public struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private static let stateIncrement: UInt64 = 0x9E37_79B9_7F4A_7C15
    private static let firstMixingMultiplier: UInt64 = 0xBF58_476D_1CE4_E5B9
    private static let secondMixingMultiplier: UInt64 = 0x94D0_49BB_1331_11EB
    private static let firstMixingShift: UInt64 = 30
    private static let secondMixingShift: UInt64 = 27
    private static let finalMixingShift: UInt64 = 31

    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= Self.stateIncrement
        var mixed = state
        mixed = (mixed ^ (mixed >> Self.firstMixingShift)) &* Self.firstMixingMultiplier
        mixed = (mixed ^ (mixed >> Self.secondMixingShift)) &* Self.secondMixingMultiplier
        return mixed ^ (mixed >> Self.finalMixingShift)
    }
}
