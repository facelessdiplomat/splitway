struct CustomServiceActions {
    let edit: @MainActor () -> Void
    let delete: @MainActor () -> Void
}
