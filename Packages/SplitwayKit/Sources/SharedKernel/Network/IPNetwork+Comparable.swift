extension IPNetwork: Comparable {
    public static func < (lhs: IPNetwork, rhs: IPNetwork) -> Bool {
        (lhs.address, lhs.prefixLength) < (rhs.address, rhs.prefixLength)
    }
}
