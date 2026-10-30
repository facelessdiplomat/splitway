public protocol UserspaceConnectionReceiver: Sendable {
    func receive(_ bytes: UnsafeRawBufferPointer)

    func finish(_ error: UserspaceNetworkError?)
}
