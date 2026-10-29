extension NetworkPort: Comparable {
    public static func < (lhs: NetworkPort, rhs: NetworkPort) -> Bool {
        lhs.value < rhs.value
    }
}
