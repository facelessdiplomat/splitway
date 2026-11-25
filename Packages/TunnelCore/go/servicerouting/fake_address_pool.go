package servicerouting

import (
	"net/netip"
	"strings"
	"sync"
	"time"
)

type fakeNetworks struct {
	ipv4 netip.Prefix
	ipv6 netip.Prefix
}

type fakeAddressPool struct {
	mutex sync.Mutex
	clock func() time.Time
	start time.Time
	ipv4  *fakeAddressFamily
	ipv6  *fakeAddressFamily
}

func newFakeAddressPool(networks fakeNetworks, clock func() time.Time, capacity int) *fakeAddressPool {
	return &fakeAddressPool{
		clock: clock,
		start: clock(),
		ipv4:  newFakeAddressFamily(networks.ipv4, capacity),
		ipv6:  newFakeAddressFamily(networks.ipv6, capacity),
	}
}

func (pool *fakeAddressPool) fakeFor(name string, real netip.Addr) (netip.Addr, bool) {
	pool.mutex.Lock()
	defer pool.mutex.Unlock()
	family := pool.familyOf(real)
	if family == nil {
		return netip.Addr{}, false
	}
	return family.fakeFor(strings.ToLower(name), real, pool.clock().Sub(pool.start))
}

func (pool *fakeAddressPool) realAddress(fake netip.Addr) (netip.Addr, bool) {
	pool.mutex.Lock()
	defer pool.mutex.Unlock()
	entry, isKnown := pool.entry(fake)
	if !isKnown {
		return netip.Addr{}, false
	}
	return entry.real, true
}

func (pool *fakeAddressPool) connectionOpened(fake netip.Addr) {
	pool.mutex.Lock()
	defer pool.mutex.Unlock()
	if entry, isKnown := pool.entry(fake); isKnown {
		entry.connectionCount++
	}
}

func (pool *fakeAddressPool) connectionClosed(fake netip.Addr) {
	pool.mutex.Lock()
	defer pool.mutex.Unlock()
	if entry, isKnown := pool.entry(fake); isKnown && entry.connectionCount > 0 {
		entry.connectionCount--
	}
}

func (pool *fakeAddressPool) supportsFamilyOf(address netip.Addr) bool {
	return pool.familyOf(address) != nil
}

func (pool *fakeAddressPool) entry(fake netip.Addr) (*fakeAddressEntry, bool) {
	family := pool.familyOf(fake)
	if family == nil {
		return nil, false
	}
	return family.entry(fake)
}

func (pool *fakeAddressPool) familyOf(address netip.Addr) *fakeAddressFamily {
	if address.Is4() {
		return pool.ipv4
	}
	return pool.ipv6
}
