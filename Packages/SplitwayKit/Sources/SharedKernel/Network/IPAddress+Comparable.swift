extension IPAddress: Comparable {
    public static func < (lhs: IPAddress, rhs: IPAddress) -> Bool {
        (lhs.family, lhs.value) < (rhs.family, rhs.value)
    }
}
