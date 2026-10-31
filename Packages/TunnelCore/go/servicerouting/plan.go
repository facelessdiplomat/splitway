package servicerouting

import "net/netip"

type Plan struct {
	VirtualDNS  netip.Addr
	FakeNetwork netip.Prefix
	UpstreamDNS netip.Addr
}
