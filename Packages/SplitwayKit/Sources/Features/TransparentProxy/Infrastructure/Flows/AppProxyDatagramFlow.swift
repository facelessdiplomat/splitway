#if os(macOS)
    import Foundation
    import Network
    import NetworkExtension
    import Synchronization
    import TransparentProxy

    public final class AppProxyDatagramFlow: ProxiedDatagramFlow {
        private let flow: Mutex<NEAppProxyUDPFlow>

        public init(_ flow: sending NEAppProxyUDPFlow) {
            self.flow = Mutex(flow)
        }

        public func open(completion: @escaping @Sendable (ProxiedFlowError?) -> Void) {
            flow.withLock { flow in
                flow.open(withLocalFlowEndpoint: nil) { error in
                    completion(error.map(ProxiedFlowError.init(appProxyError:)))
                }
            }
        }

        public func readDatagrams(
            completion: @escaping @Sendable (Result<[ProxiedDatagram], ProxiedFlowError>) -> Void
        ) {
            flow.withLock { flow in
                flow.readDatagrams { pairs, error in
                    if let error {
                        completion(.failure(ProxiedFlowError(appProxyError: error)))
                        return
                    }
                    let received = pairs ?? []
                    let datagrams = received.compactMap { payload, endpoint in
                        FlowEndpoint(endpoint).map { remote in ProxiedDatagram(payload: payload, remoteEndpoint: remote)
                        }
                    }
                    if datagrams.isEmpty, !received.isEmpty {
                        self.readDatagrams(completion: completion)
                    } else {
                        completion(.success(datagrams))
                    }
                }
            }
        }

        public func writeDatagrams(
            _ datagrams: [ProxiedDatagram],
            completion: @escaping @Sendable (ProxiedFlowError?) -> Void
        ) {
            let pairs = datagrams.compactMap { datagram in
                datagram.remoteEndpoint.networkEndpoint.map { endpoint in (datagram.payload, endpoint) }
            }
            flow.withLock { flow in
                flow.writeDatagrams(pairs) { error in
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
