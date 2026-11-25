import AppRouting
import SharedKernel

public enum ServiceRoutingWarning: Sendable, Hashable {
    case emptySelection
    case networksOutsideAllowedIPs(ServiceIdentifier, [IPNetwork])
    case allowedIPsWithoutDefaultRoute
    case resolverOutsideAllowedIPs(IPAddress)
    case fakeNetworkConflict
}
