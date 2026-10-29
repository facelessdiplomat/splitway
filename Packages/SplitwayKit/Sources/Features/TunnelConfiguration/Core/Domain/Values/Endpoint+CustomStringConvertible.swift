extension Endpoint: CustomStringConvertible {
    public var description: String {
        switch host {
        case .address(let address) where address.family == .ipv6: "[\(address)]:\(port)"
        case .address(let address): "\(address):\(port)"
        case .name(let name): "\(name):\(port)"
        }
    }
}
