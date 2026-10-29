#if canImport(MetricKit)
    import Diagnostics
    import Foundation
    import MetricKit

    public final class MetricKitReportCollector: NSObject, MXMetricManagerSubscriber, Sendable {
        private let store: FileDiagnosticReportStore

        public init(store: FileDiagnosticReportStore) {
            self.store = store
        }

        public func start() {
            let manager = MXMetricManager.shared
            manager.add(self)
            didReceive(manager.pastDiagnosticPayloads)
        }

        public func didReceive(_ payloads: [MXDiagnosticPayload]) {
            try? store.save(MetricKitReportConversion.reports(from: payloads))
        }
    }
#endif
