struct ResolvedAddressKinds: Sendable, Equatable {
    var fakeIPv4 = 0
    var realIPv4 = 0
    var fakeIPv6 = 0
    var mappedFakeIPv4 = 0
    var synthesizedFromFakeIPv4 = 0
    var realIPv6 = 0

    var isOnlyFake: Bool {
        fakeIPv4 > 0 && realIPv4 == 0 && realIPv6 == 0
    }

    var hasAnyFake: Bool {
        fakeIPv4 + fakeIPv6 + mappedFakeIPv4 + synthesizedFromFakeIPv4 > 0
    }

    var summary: String {
        "v4-fake=\(fakeIPv4) v4-real=\(realIPv4) v6-fake=\(fakeIPv6) v6-mapped=\(mappedFakeIPv4)"
            + " v6-synthesized=\(synthesizedFromFakeIPv4) v6-real=\(realIPv6)"
    }
}
