public protocol UserspaceConnection: Sendable {
    func startReceiving(
        into receiver: any UserspaceConnectionReceiver,
        readByteCount: Int,
        initialCredit: Int
    ) throws(UserspaceNetworkError)

    func write(_ bytes: UnsafeRawBufferPointer) throws(UserspaceNetworkError) -> Int

    func grant(_ byteCount: Int)

    func close(_ closing: UserspaceConnectionClosing)
}
