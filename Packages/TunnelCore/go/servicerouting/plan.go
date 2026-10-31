package servicerouting

import (
	"errors"
	"fmt"
	"net/netip"
)

const reservedAddressBitCount = 8

var errInvalidPlan = errors.New("invalid service routing plan")

type Plan struct {
	VirtualDNS      netip.Addr
	UpstreamDNS     netip.Addr
	FakeIPv4Network netip.Prefix
	FakeIPv6Network netip.Prefix
}

func (plan Plan) validate() error {
	if !plan.FakeIPv4Network.IsValid() || !plan.FakeIPv4Network.Addr().Is4() || !hasUnreservedAddresses(plan.FakeIPv4Network) {
		return fmt.Errorf("%w: the fake IPv4 network %v needs more than %d addresses", errInvalidPlan, plan.FakeIPv4Network, reservedFakeAddressCount)
	}
	if !plan.VirtualDNS.Is4() || !isReserved(plan.VirtualDNS, plan.FakeIPv4Network) {
		return fmt.Errorf("%w: the virtual resolver %v must be among the first %d addresses of %v", errInvalidPlan, plan.VirtualDNS, reservedFakeAddressCount, plan.FakeIPv4Network)
	}
	if !plan.UpstreamDNS.Is4() || plan.FakeIPv4Network.Contains(plan.UpstreamDNS) {
		return fmt.Errorf("%w: the upstream resolver %v must be an IPv4 address outside %v", errInvalidPlan, plan.UpstreamDNS, plan.FakeIPv4Network)
	}
	if plan.FakeIPv6Network.IsValid() && (!plan.FakeIPv6Network.Addr().Is6() || plan.FakeIPv6Network.Addr().Is4In6() || !hasUnreservedAddresses(plan.FakeIPv6Network)) {
		return fmt.Errorf("%w: the fake IPv6 network %v needs more than %d addresses", errInvalidPlan, plan.FakeIPv6Network, reservedFakeAddressCount)
	}
	return nil
}

func (plan Plan) fakeNetworks() fakeNetworks {
	return fakeNetworks{ipv4: plan.FakeIPv4Network, ipv6: plan.FakeIPv6Network}
}

func (plan Plan) fakePrefixes() []netip.Prefix {
	if plan.FakeIPv6Network.IsValid() {
		return []netip.Prefix{plan.FakeIPv4Network, plan.FakeIPv6Network}
	}
	return []netip.Prefix{plan.FakeIPv4Network}
}

func hasUnreservedAddresses(network netip.Prefix) bool {
	return network.Addr().BitLen()-network.Bits() > reservedAddressBitCount
}

func isReserved(address netip.Addr, network netip.Prefix) bool {
	firstUnreserved := addressAfter(network.Masked().Addr(), reservedFakeAddressCount)
	return network.Contains(address) && address.Less(firstUnreserved)
}
