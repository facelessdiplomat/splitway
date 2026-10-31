import Darwin
import SystemConfiguration
import TransparentProxy

public struct PrimaryInterfaceMTUReader: NetworkPathMTUReader {
    private static let storeName = "Splitway.PrimaryInterfaceMTU"
    private static let globalIPv4Key = "State:/Network/Global/IPv4"
    private static let primaryInterfaceKey = "PrimaryInterface"

    public init() {}

    public func currentPathMTU() -> Int? {
        guard let store = SCDynamicStoreCreate(nil, Self.storeName as CFString, nil, nil),
            let state = SCDynamicStoreCopyValue(store, Self.globalIPv4Key as CFString) as? [String: Any],
            let interfaceName = state[Self.primaryInterfaceKey] as? String
        else { return nil }
        return Self.mtu(ofInterfaceNamed: interfaceName)
    }

    private static func mtu(ofInterfaceNamed name: String) -> Int? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let first = interfaces else { return nil }
        defer { freeifaddrs(interfaces) }
        for entry in sequence(first: first, next: { entry in entry.pointee.ifa_next }) {
            let interface = entry.pointee
            guard interface.ifa_addr?.pointee.sa_family == UInt8(AF_LINK), String(cString: interface.ifa_name) == name,
                let statistics = interface.ifa_data
            else { continue }
            return Int(statistics.assumingMemoryBound(to: if_data.self).pointee.ifi_mtu)
        }
        return nil
    }
}
