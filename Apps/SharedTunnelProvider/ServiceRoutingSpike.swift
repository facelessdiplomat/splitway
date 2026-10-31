#if os(iOS)
    import Darwin
    import NetworkExtension
    import TunnelCoreAdapter

    enum ServiceRoutingSpike {
        static let plan = TunnelCoreServiceRoutingPlan(
            virtualDNS: "198.18.0.2",
            fakeNetwork: "198.18.0.0/15",
            upstreamDNS: "1.1.1.1"
        )
        static let matchedDomains = ["ipify.org", "ovh.net"]
        private static let fakeNetworkAddress = "198.18.0.0"
        private static let fakeNetworkMask = "255.254.0.0"
        private static let samplingInterval = Duration.seconds(1)
        private static let bytesPerMegabyte = 1_048_576.0

        static func apply(to settings: NEPacketTunnelNetworkSettings) {
            settings.ipv4Settings?.includedRoutes = [
                NEIPv4Route(destinationAddress: fakeNetworkAddress, subnetMask: fakeNetworkMask)
            ]
            settings.ipv4Settings?.excludedRoutes = []
            settings.ipv6Settings = nil
            let dns = NEDNSSettings(servers: [plan.virtualDNS])
            dns.matchDomains = matchedDomains
            dns.matchDomainsNoSearch = true
            settings.dnsSettings = dns
        }

        static func sampleFootprint(into record: @escaping @Sendable (String) -> Void) -> Task<Void, Never> {
            Task.detached {
                var peak = 0.0
                while !Task.isCancelled {
                    let available = Double(os_proc_available_memory()) / bytesPerMegabyte
                    let footprint = Self.footprint()
                    let current = Double(footprint.current) / bytesPerMegabyte
                    peak = max(peak, current)
                    record(
                        "SP-4 footprint-mb=\(Self.text(current)) peak-mb=\(Self.text(peak))"
                            + " lifetime-peak-mb=\(Self.text(Double(footprint.lifetimePeak) / bytesPerMegabyte))"
                            + " available-mb=\(Self.text(available))")
                    try? await Task.sleep(for: samplingInterval)
                }
            }
        }

        private static func footprint() -> (current: UInt64, lifetimePeak: Int64) {
            var information = task_vm_info_data_t()
            var count = mach_msg_type_number_t(
                MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
            let result = withUnsafeMutablePointer(to: &information) { pointer in
                pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { words in
                    task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), words, &count)
                }
            }
            guard result == KERN_SUCCESS else { return (0, 0) }
            return (information.phys_footprint, information.ledger_phys_footprint_peak)
        }

        private static func text(_ megabytes: Double) -> String {
            String(format: "%.1f", megabytes)
        }
    }
#endif
