#if os(macOS)
    import Foundation
    import NetworkExtension
    import Synchronization
    import TransparentProxy

    public final class AppProxyStreamFlow: ProxiedStreamFlow {
        private let flow: Mutex<NEAppProxyTCPFlow>

        public init(_ flow: sending NEAppProxyTCPFlow) {
            self.flow = Mutex(flow)
        }

        public func open(completion: @escaping @Sendable (ProxiedFlowError?) -> Void) {
            flow.withLock { flow in
                flow.open(withLocalFlowEndpoint: nil) { error in
                    completion(error.map(ProxiedFlowError.init(appProxyError:)))
                }
            }
        }

        public func read(completion: @escaping @Sendable (Result<Data, ProxiedFlowError>) -> Void) {
            flow.withLock { flow in
                flow.readData { data, error in
                    if let error {
                        completion(.failure(ProxiedFlowError(appProxyError: error)))
                    } else {
                        completion(.success(data ?? Data()))
                    }
                }
            }
        }

        public func write(_ data: Data, completion: @escaping @Sendable (ProxiedFlowError?) -> Void) {
            flow.withLock { flow in
                flow.write(data) { error in
                    completion(error.map(ProxiedFlowError.init(appProxyError:)))
                }
            }
        }

        public func closeRead(with error: ProxiedFlowError?) {
            flow.withLock { flow in flow.closeReadWithError(error?.appProxyError) }
        }

        public func closeWrite(with error: ProxiedFlowError?) {
            flow.withLock { flow in flow.closeWriteWithError(error?.appProxyError) }
        }
    }
#endif
