import Foundation
import Synchronization

enum BackgroundDownload {
    private static let fallbackBundleIdentifier = "com.facelessdiplomat.splitway.routing-probe"
    private static let handOverDelay = Duration.seconds(1)
    private static let pollingInterval = Duration.milliseconds(100)

    static func start(_ address: URL, delaySeconds: Int) async -> [String] {
        let session = URLSession(configuration: configuration())
        let task = session.downloadTask(with: address)
        task.earliestBeginDate = Date().addingTimeInterval(TimeInterval(delaySeconds))
        task.resume()
        try? await Task.sleep(for: handOverDelay)
        return ["background started task=\(task.taskIdentifier) begins-in=\(delaySeconds)s"]
    }

    static func collect(timeoutSeconds: Int) async -> [String] {
        let collector = BackgroundDownloadCollector()
        let session = URLSession(configuration: configuration(), delegate: collector, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let deadline = ContinuousClock.now + .seconds(timeoutSeconds)
        while ContinuousClock.now < deadline {
            if let outcome = collector.outcome {
                return ["background \(outcome)"]
            }
            try? await Task.sleep(for: pollingInterval)
        }
        return ["background failed timeout"]
    }

    private static func configuration() -> URLSessionConfiguration {
        let identifier = (Bundle.main.bundleIdentifier ?? fallbackBundleIdentifier) + ".background"
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = false
        return configuration
    }
}

final class BackgroundDownloadCollector: NSObject, URLSessionDownloadDelegate, Sendable {
    private let body = Mutex<String?>(nil)
    private let finished = Mutex<String?>(nil)

    var outcome: String? {
        finished.withLock { outcome in outcome }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let text = (try? String(contentsOf: location, encoding: .utf8)) ?? ""
        body.withLock { body in body = text.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        let text = body.withLock { body in body }
        let outcome = error.map { error in "failed \(error.localizedDescription)" } ?? "ok \(text ?? "")"
        finished.withLock { finished in finished = outcome }
    }
}
