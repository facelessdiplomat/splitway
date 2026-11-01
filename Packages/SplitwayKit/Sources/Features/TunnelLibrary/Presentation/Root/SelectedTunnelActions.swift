struct SelectedTunnelActions {
    let row: TunnelRow
    let toggleConnection: @MainActor () -> Void
    let edit: (@MainActor () -> Void)?
    let duplicate: @MainActor () -> Void
    let export: @MainActor () -> Void
    let delete: @MainActor () -> Void
}
