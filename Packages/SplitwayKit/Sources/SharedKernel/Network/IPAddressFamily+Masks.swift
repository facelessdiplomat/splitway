extension IPAddressFamily {
    func networkMask(prefixLength: Int) -> UInt128 {
        allAddressBits & ~hostMask(prefixLength: prefixLength)
    }

    func hostMask(prefixLength: Int) -> UInt128 {
        let hostBitCount = bitWidth - prefixLength
        return hostBitCount == UInt128.bitWidth ? .max : (1 << hostBitCount) - 1
    }
}
