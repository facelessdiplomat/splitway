extension IPNetwork {
    public init(host address: IPAddress) {
        self.init(address: address, trustedPrefixLength: address.family.bitWidth)
    }
}
