import ServiceCatalog

public struct ServicePickerActions: Sendable {
    let loadCatalog: LoadServiceCatalogUseCase
    let saveCustomService: SaveCustomServiceUseCase
    let deleteCustomService: DeleteCustomServiceUseCase
    let compiler: ServiceRoutingPlanCompiler

    public init(
        bundled: any BundledServiceCatalog,
        custom: any CustomServiceRepository,
        compiler: ServiceRoutingPlanCompiler = ServiceRoutingPlanCompiler()
    ) {
        loadCatalog = LoadServiceCatalogUseCase(bundled: bundled, custom: custom)
        saveCustomService = SaveCustomServiceUseCase(repository: custom)
        deleteCustomService = DeleteCustomServiceUseCase(repository: custom)
        self.compiler = compiler
    }
}
