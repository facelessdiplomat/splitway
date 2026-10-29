extension IPNetwork: CustomStringConvertible {
    public var description: String {
        "\(address)/\(prefixLength)"
    }
}
