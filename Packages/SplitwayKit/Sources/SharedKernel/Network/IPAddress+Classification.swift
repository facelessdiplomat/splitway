extension IPAddress {
    public var isLoopback: Bool {
        belongs(toAnyOf: IPNetwork.loopbackNetworks)
    }

    public var isLinkLocal: Bool {
        belongs(toAnyOf: IPNetwork.linkLocalNetworks)
    }

    public var isPrivate: Bool {
        belongs(toAnyOf: IPNetwork.privateNetworks)
    }

    public var isMulticast: Bool {
        belongs(toAnyOf: IPNetwork.multicastNetworks)
    }

    private func belongs(toAnyOf networks: [IPNetwork]) -> Bool {
        networks.contains { network in network.contains(self) }
    }
}
