public struct TunnelAdditionOptions: Sendable {
    let methods: [TunnelAdditionMethod]
    let add: @MainActor @Sendable (TunnelAdditionMethod) -> Void
    let paste: @MainActor @Sendable ([String]) -> Void

    public init(
        methods: [TunnelAdditionMethod],
        add: @escaping @MainActor @Sendable (TunnelAdditionMethod) -> Void,
        paste: @escaping @MainActor @Sendable ([String]) -> Void
    ) {
        self.methods = methods
        self.add = add
        self.paste = paste
    }
}
