extension IPNetworkSet: CustomStringConvertible {
    public var description: String {
        networks.map(\.description).joined(separator: ", ")
    }
}
