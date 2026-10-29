import SharedKernel

public enum RelayTarget: Sendable, Hashable {
    case address(IPAddress)
    case hostname(DomainName)
}
