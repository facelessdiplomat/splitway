import Diagnostics
import Observation

@MainActor
@Observable
public final class CrashReportModel: Identifiable {
    public private(set) var state = CrashReportState.preparing

    private let prepareReport: PrepareCrashReportUseCase

    public init(prepareReport: PrepareCrashReportUseCase) {
        self.prepareReport = prepareReport
    }

    public func prepare() async {
        do {
            state = .ready(try await prepareReport.execute())
        } catch {
            state = .unavailable
        }
    }
}
