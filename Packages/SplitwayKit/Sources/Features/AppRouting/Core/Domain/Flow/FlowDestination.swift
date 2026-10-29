import SharedKernel

public enum FlowDestination: Sendable, Hashable {
    case address(IPAddress)
    case hostname(String)
}
