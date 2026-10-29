import Darwin
import PacketTunnel

public struct UtunDescriptorLocator: TunnelInterfaceLocator {
    private static let controlSocketLevel: Int32 = 2
    private static let interfaceNameOption: Int32 = 2
    private static let scannedDescriptors: ClosedRange<Int32> = 0...1024
    private static let tunnelInterfacePrefix = "utun"

    public init() {}

    public func tunnelFileDescriptor() -> Int32? {
        Self.scannedDescriptors.first(where: Self.isTunnelInterface)
    }

    private static func isTunnelInterface(_ descriptor: Int32) -> Bool {
        var name = [CChar](repeating: 0, count: Int(IFNAMSIZ))
        var length = socklen_t(name.count)
        guard getsockopt(descriptor, controlSocketLevel, interfaceNameOption, &name, &length) == 0 else { return false }
        let interfaceName = name.withUnsafeBufferPointer { buffer in buffer.baseAddress.map { String(cString: $0) } }
        return interfaceName?.hasPrefix(tunnelInterfacePrefix) == true
    }
}
