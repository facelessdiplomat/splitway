public struct TunnelAdditionOptions: Sendable {
    let methods: [TunnelAdditionMethod]
    let add: @MainActor @Sendable (TunnelAdditionMethod) -> Void

    public init(methods: [TunnelAdditionMethod], add: @escaping @MainActor @Sendable (TunnelAdditionMethod) -> Void) {
        self.methods = methods
        self.add = add
    }
}
