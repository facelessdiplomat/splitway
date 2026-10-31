import Foundation
import Synchronization

final class TransactionTimesCollector: NSObject, URLSessionTaskDelegate, Sendable {
    private let collected = Mutex<TransactionTimes?>(nil)

    var times: TransactionTimes? {
        collected.withLock { times in times }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let transaction = metrics.transactionMetrics.last else { return }
        let times = TransactionTimes(transaction)
        collected.withLock { collected in collected = times }
    }
}
