#if os(macOS)
    import Foundation
    import Network
    import SharedKernel
    import TransparentProxy

    extension FlowEndpoint {
        public init?(_ endpoint: NWEndpoint) {
            guard case .hostPort(let host, let port) = endpoint,
                let address = Self.address(of: host),
                let flowPort = try? NetworkPort(Int(port.rawValue))
            else { return nil }
            self.init(address: address, port: flowPort)
        }

        public var networkEndpoint: NWEndpoint? {
            guard let port = NWEndpoint.Port(rawValue: port.value), let host = Self.host(of: address) else {
                return nil
            }
            return .hostPort(host: host, port: port)
        }

        private static func address(of host: NWEndpoint.Host) -> SharedKernel.IPAddress? {
            switch host {
            case .ipv4(let address): SharedKernel.IPAddress(networkOrderBytes: address.rawValue)
            case .ipv6(let address): SharedKernel.IPAddress(networkOrderBytes: address.rawValue)
            default: nil
            }
        }

        private static func host(of address: SharedKernel.IPAddress) -> NWEndpoint.Host? {
            let bytes = Data(address.networkOrderBytes)
            switch address.family {
            case .ipv4: return IPv4Address(bytes).map(NWEndpoint.Host.ipv4)
            case .ipv6: return IPv6Address(bytes).map(NWEndpoint.Host.ipv6)
            }
        }
    }
#endif
